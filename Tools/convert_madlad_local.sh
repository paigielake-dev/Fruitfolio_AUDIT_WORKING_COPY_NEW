#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ $# -ne 4 ]]; then
  echo 'Usage: bash Tools/convert_madlad_local.sh <verified-official-snapshot-dir> <40-char-source-revision> <llama-quantize-path> <output-dir>' >&2
  exit 2
fi
snapshot=$1
revision=$2
quantizer=$3
output_dir=$4
[[ -f "$snapshot/config.json" ]] || { echo 'Missing official snapshot config.json' >&2; exit 2; }
[[ -f "$snapshot/spiece.model" || -f "$snapshot/tokenizer.model" ]] || { echo 'Missing original SentencePiece model' >&2; exit 2; }
[[ -x "$quantizer" ]] || { echo 'Build the vendored llama-quantize tool first' >&2; exit 2; }
mkdir -p "$output_dir"
[[ ! -e "$output_dir/MADLAD400.gguf" && ! -e "$output_dir/MADLAD400-f16.gguf" && ! -e "$output_dir/MADLAD400.manifest.json" ]] || {
  echo 'Preserving existing output artifacts; select a new directory.' >&2; exit 2;
}
python3 llama.cpp/convert_hf_to_gguf.py "$snapshot" --outfile "$output_dir/MADLAD400-f16.gguf" --outtype f16
"$quantizer" "$output_dir/MADLAD400-f16.gguf" "$output_dir/MADLAD400.gguf" Q4_K_M
python3 Tools/prepare_madlad_manifest.py --model "$output_dir/MADLAD400.gguf" \
  --config "$snapshot/config.json" --source-revision "$revision" --output "$output_dir/MADLAD400.manifest.json"
echo 'Conversion complete. Keep F16 until quantized inference and quality tests pass. Add the GGUF and manifest to the app resource target and run device tests.'
