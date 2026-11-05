#!/usr/bin/env python3
"""Create the iOS manifest from a converted GGUF's actual metadata/vocabulary.

No inference or translation-quality claim is made by this packaging tool.
The caller supplies the official source snapshot's immutable revision.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import sys


def manifest_from_metadata(*, model_name, checksum, revision, config, architecture, tokenizer, tokens, context_length):
    if not re.fullmatch(r'[0-9a-f]{40}', revision):
        raise ValueError('An immutable official Hugging Face revision is required')
    if config.get('model_type') != 't5' or architecture != 't5' or tokenizer != 't5':
        raise ValueError('Expected a T5 encoder-decoder with embedded T5 SentencePiece vocabulary')
    tags = sorted({m.group(1) for token in tokens if (m := re.fullmatch(r'<2([A-Za-z][A-Za-z0-9_-]{0,15})>', token))})
    if not tags or 'en' not in tags:
        raise ValueError('No complete MADLAD target-tag vocabulary was found')
    if not 64 <= context_length <= 4096:
        raise ValueError('Unsupported runtime context length')
    return dict(modelFile=model_name, sha256=checksum, sourceRepository='google/madlad400-3b-mt',
                sourceRevision=revision, architecture=architecture, tokenizer='embedded-sentencepiece',
                supportedLanguageTags=tags, contextLength=context_length,
                maximumOutputTokens=min(256, context_length - 1))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--model', type=Path, required=True)
    parser.add_argument('--config', type=Path, required=True)
    parser.add_argument('--source-revision', required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    if args.output.exists():
        parser.error('Output already exists; preserve or remove it explicitly before regenerating')
    model = args.model.resolve(strict=True)
    with model.open('rb') as stream:
        if stream.read(4) != b'GGUF':
            parser.error('The model is not GGUF (Git LFS pointers are not model files)')
    sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'llama.cpp/gguf-py'))
    from gguf import GGUFReader
    reader = GGUFReader(str(model))
    if not reader.tensors:
        parser.error('A vocabulary-only artifact cannot execute inference')
    def field(key):
        value = reader.get_field(key)
        if value is None:
            parser.error('Missing GGUF field: ' + key)
        return value.contents()
    with model.open('rb') as stream:
        checksum = hashlib.file_digest(stream, 'sha256').hexdigest()
    manifest = manifest_from_metadata(model_name=model.name, checksum=checksum, revision=args.source_revision,
        config=json.loads(args.config.read_text()), architecture=field('general.architecture'),
        tokenizer=field('tokenizer.ggml.model'), tokens=field('tokenizer.ggml.tokens'),
        context_length=int(field('t5.context_length')))
    args.output.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + '\n')
    print(f'Manifest written for {len(manifest["supportedLanguageTags"])} vocabulary tags; inference NOT verified.')

if __name__ == '__main__':
    main()
