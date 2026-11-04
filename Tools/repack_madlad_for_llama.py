#!/usr/bin/env python3
"""Experimental lossless GGUF tensor repack; not medical or iOS validation.
Run with PYTHONPATH=llama.cpp/gguf-py and sentencepiece, protobuf, numpy.
Keeps original quantized tensor payloads and checks every output byte hash.
"""
import argparse
import hashlib
import json
from pathlib import Path
import gguf
import sentencepiece as spm
from sentencepiece import sentencepiece_model_pb2


def file_hash(path):
    digest = hashlib.sha256()
    with open(path, "rb") as stream:
        for block in iter(lambda: stream.read(8 * 1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('model_directory', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    base = args.model_directory
    config = json.loads((base / 'config.json').read_text())
    assert config['model_type'] == 't5' and config['is_encoder_decoder']
    original = base / 'model-q4k.gguf'
    assert file_hash(original) == 'ea6e5531a3e95213c7f0635988d119e078a655c09306e47851e15d4c0c3f9c37'
    reader = gguf.GGUFReader(original)
    writer = gguf.GGUFWriter(args.output, 't5')
    writer.add_name('MADLAD400 3B MT - experimental llama.cpp repack of official Q4_K')
    writer.add_context_length(config['n_positions'])
    writer.add_embedding_length(config['d_model'])
    writer.add_feed_forward_length(config['d_ff'])
    writer.add_block_count(config['num_layers'])
    writer.add_decoder_block_count(config['num_decoder_layers'])
    writer.add_head_count(config['num_heads'])
    writer.add_key_length(config['d_kv'])
    writer.add_value_length(config['d_kv'])
    writer.add_layer_norm_eps(config['layer_norm_epsilon'])
    writer.add_layer_norm_rms_eps(config['layer_norm_epsilon'])
    writer.add_relative_attn_buckets_count(config['relative_attention_num_buckets'])
    writer.add_decoder_start_token_id(config['decoder_start_token_id'])
    writer.add_file_type(gguf.LlamaFileType.MOSTLY_Q4_K_S)
    tokenizer = spm.SentencePieceProcessor(model_file=str(base / 'spiece.model'))
    proto = sentencepiece_model_pb2.ModelProto()
    proto.ParseFromString((base / 'spiece.model').read_bytes())
    assert tokenizer.vocab_size() == config['vocab_size']
    tokens, scores, types = [], [], []
    for i in range(tokenizer.vocab_size()):
        tokens.append(tokenizer.id_to_piece(i).encode('utf-8'))
        scores.append(tokenizer.get_score(i))
        kind = gguf.TokenType.NORMAL
        if tokenizer.is_unknown(i): kind = gguf.TokenType.UNKNOWN
        elif tokenizer.is_control(i): kind = gguf.TokenType.CONTROL
        elif tokenizer.is_unused(i): kind = gguf.TokenType.UNUSED
        elif tokenizer.is_byte(i): kind = gguf.TokenType.BYTE
        types.append(kind)
    writer.add_tokenizer_model('t5')
    writer.add_tokenizer_pre('default')
    writer.add_token_list(tokens)
    writer.add_token_scores(scores)
    writer.add_token_types(types)
    writer.add_add_space_prefix(proto.normalizer_spec.add_dummy_prefix)
    writer.add_remove_extra_whitespaces(proto.normalizer_spec.remove_extra_whitespaces)
    writer.add_precompiled_charsmap(proto.normalizer_spec.precompiled_charsmap)
    writer.add_eos_token_id(config['eos_token_id'])
    writer.add_pad_token_id(config['pad_token_id'])
    writer.add_unk_token_id(tokenizer.unk_id())
    writer.add_add_bos_token(False)
    writer.add_add_eos_token(True)
    mapping = gguf.get_tensor_name_map(gguf.MODEL_ARCH.T5, config['num_layers'])
    hashes = {}
    for tensor in reader.tensors:
        name = 'shared.weight' if tensor.name in ['decoder.embed_tokens.weight', 'encoder.embed_tokens.weight'] else tensor.name
        target = mapping.get_name(name, try_suffixes=('.weight',))
        if target is None: raise ValueError('unmapped tensor: ' + tensor.name)
        if target in hashes: raise ValueError('duplicate tensor: ' + target)
        hashes[target] = hashlib.sha256(tensor.data).hexdigest()
        writer.add_tensor(target, tensor.data, raw_dtype=tensor.tensor_type)
    writer.write_header_to_file()
    writer.write_kv_data_to_file()
    writer.write_tensors_to_file()
    writer.close()
    converted = gguf.GGUFReader(args.output)
    assert len(converted.tensors) == len(hashes)
    for tensor in converted.tensors:
        assert hashlib.sha256(tensor.data).hexdigest() == hashes[tensor.name], tensor.name
    report = {'status': 'all quantized tensor payloads preserved byte-for-byte',
              'tensor_count': len(hashes), 'output_sha256': file_hash(args.output),
              'source_sha256': file_hash(original),
              'warning': 'Experimental format adaptation only; requires runtime, numerical, translation, medical and iOS validation.'}
    args.output.with_suffix('.repack.json').write_text(json.dumps(report, indent=2))
    print(json.dumps(report, indent=2))

if __name__ == '__main__': main()
