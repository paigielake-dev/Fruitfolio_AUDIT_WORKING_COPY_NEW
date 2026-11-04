//! Diagnostic only: never linked into the app or interpreted as clinical approval.
use anyhow::{anyhow, Result};
use candle_core::{Device, Tensor};
use candle_transformers::{generation::LogitsProcessor, models::quantized_t5 as t5, utils::apply_repeat_penalty};
use std::{io::Write, path::PathBuf, time::Instant};
use tokenizers::Tokenizer;

fn generate(model: &mut t5::T5ForConditionalGeneration, tokenizer: &Tokenizer,
            config: &t5::Config, prompt: &str, penalty: f32) -> Result<serde_json::Value> {
    model.clear_kv_cache();
    let started = Instant::now();
    let tag = prompt.split_once(' ').ok_or_else(|| anyhow!("missing exact target tag"))?.0;
    if tokenizer.token_to_id(tag).is_none() { return Err(anyhow!("absent exact official tag")); }
    let source_ids = tokenizer.encode(prompt, true).map_err(|e| anyhow!(e.to_string()))?.get_ids().to_vec();
    if source_ids.len() > 512 { return Err(anyhow!("input too long")); }
    let encoded = model.encode(&Tensor::new(source_ids.as_slice(), &Device::Cpu)?.unsqueeze(0)?)?;
    let mut ids = vec![config.decoder_start_token_id.unwrap_or(config.pad_token_id) as u32];
    let mut sampler = LogitsProcessor::new(42, None, None);
    let mut reached_eos = false;
    for index in 0..512 {
        let step = if index == 0 { ids.clone() } else { vec![*ids.last().unwrap()] };
        let logits = model.decode(&Tensor::new(step.as_slice(), &Device::Cpu)?.unsqueeze(0)?, &encoded)?.squeeze(0)?;
        let logits = if penalty == 1.0 { logits } else { apply_repeat_penalty(&logits, penalty, &ids[1..])? };
        let token = sampler.sample(&logits)?;
        if token as usize == config.eos_token_id { reached_eos = true; break; }
        ids.push(token);
    }
    let output = tokenizer.decode(&ids[1..], true).map_err(|e| anyhow!(e.to_string()))?;
    let unique = ids[1..].iter().collect::<std::collections::HashSet<_>>().len();
    let mut longest_repeat = 0usize;
    let mut current_repeat = 0usize;
    let mut previous = None;
    for token in &ids[1..] {
        current_repeat = if previous == Some(*token) { current_repeat + 1 } else { 1 };
        longest_repeat = longest_repeat.max(current_repeat); previous = Some(*token);
    }
    Ok(serde_json::json!({"execution":"COMPLETED", "prompt":prompt, "rawOutput":output,
        "generatedTokens":ids.len()-1, "uniqueGeneratedTokens":unique, "longestSingleTokenRun":longest_repeat,
        "reachedEOS":reached_eos, "partialOutputRejected":!reached_eos, "medicalMeaningVerified":false,
        "productionProfileChanged":false, "repeatPenalty":penalty, "maxGeneratedTokens":512,
        "wallSeconds":started.elapsed().as_secs_f64(), "inputIDs":source_ids}))
}

fn main() -> Result<()> {
    let root = PathBuf::from(std::env::args().nth(1).ok_or_else(|| anyhow!("verified official model directory required"))?);
    let mut config: t5::Config = serde_json::from_slice(&std::fs::read(root.join("config.json"))?)?;
    config.use_cache = true;
    let mut tokenizer = Tokenizer::from_file(root.join("tokenizer.json")).map_err(|e| anyhow!(e.to_string()))?;
    tokenizer.with_padding(None).with_truncation(None).map_err(|e| anyhow!(e.to_string()))?;
    let vb = t5::VarBuilder::from_gguf(root.join("model-q4k.gguf"), &Device::Cpu)?;
    let mut model = t5::T5ForConditionalGeneration::load(vb, &config)?;
    let prompts = ["<2ay> Do not stop taking prescribed medication.",
                   "<2ay> These recorded values do not confirm a diagnosis",
                   "<2es> This is educational information, not medical advice.",
                   "<2fr> This estimate does not confirm ovulation."];
    for penalty in [1.0f32, 1.05, 1.10, 1.20] {
        for prompt in prompts {
            let result = match generate(&mut model, &tokenizer, &config, prompt, penalty) {
                Ok(value) => value,
                Err(error) => serde_json::json!({"execution":"FAIL", "prompt":prompt,
                    "repeatPenalty":penalty, "error":error.to_string(), "medicalMeaningVerified":false,
                    "productionProfileChanged":false})
            };
            println!("{}", result);
            std::io::stdout().flush()?;
        }
    }
    Ok(())
}
