#!/usr/bin/env python3
"""Apply a bounded, reproducible Candle T5 embedding memory adaptation.
The official GGUF bytes, quantization, decoder and tokenizer are unchanged.
"""
from pathlib import Path
import hashlib
root=Path(__file__).resolve().parents[1]
p=root/'TranslationInvestigation/candle-runtime-investigation/candle-transformers/src/models/quantized_t5.rs'
s=p.read_text()
marker='// Fruitfolio: gather exact quantized embedding rows without expanding the vocabulary.'
if marker in s:
 assert hashlib.sha256(p.read_bytes()).hexdigest()=='ece2a21034cfb8b390edcfc8b79b0a5a50bb90bbc532de42f307c642e35a5b1c', 'Unexpected modified adapted source'
 print('Candle MADLAD row embedding adaptation already present')
 raise SystemExit(0)
assert hashlib.sha256(p.read_bytes()).hexdigest()=='283f82a73accd79a60cdf9b932fb0c1f301d204a568e387ce6565d59f829ec8f', 'Unexpected upstream T5 source; do not patch an unknown revision'
s=s.replace('use crate::quantized_nn::Embedding;', '''// Fruitfolio: gather exact quantized embedding rows without expanding the vocabulary.
// Uses upstream QTensor::embedding; no rounding or weight changes are introduced.
#[derive(Debug, Clone)]
struct Embedding {
    weight: std::sync::Arc<candle::quantized::QTensor>,
}
impl Embedding {
    fn new(rows: usize, hidden: usize, vb: VarBuilder) -> Result<Self> {
        Ok(Self { weight: vb.get((rows, hidden), "weight")? })
    }
    fn embeddings(&self) -> Result<Tensor> {
        // Only tied-output models need the full table. Official MADLAD is untied.
        self.weight.dequantize(&self.weight.device())
    }
}
impl Module for Embedding {
    fn forward(&self, ids: &Tensor) -> Result<Tensor> { self.weight.embedding(ids) }
}''')
assert s.count('self.shared.embeddings().t()?')==1
s=s.replace('self.shared.embeddings().t()?', 'self.shared.embeddings()?.t()?')
p.write_text(s)
print('Applied exact-row embedding adaptation to pinned official Candle T5 source')
