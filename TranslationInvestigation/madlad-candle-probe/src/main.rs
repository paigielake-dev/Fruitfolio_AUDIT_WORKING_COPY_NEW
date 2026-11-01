use anyhow::{Result, anyhow};
use candle_core::{Device, Tensor};
use candle_transformers::{models::quantized_t5 as t5, generation::LogitsProcessor};
use tokenizers::Tokenizer;
use std::{path::PathBuf, time::Instant, io::Write};
fn main() -> Result<()> {
    let args: Vec<String> = std::env::args().collect();
    let root = PathBuf::from(args.get(1).ok_or_else(|| anyhow!("model directory required"))?);
    let input_arg = args.get(2).ok_or_else(|| anyhow!("prompt or --batch-file required"))?;
    let prompts: Vec<String> = if input_arg == "--batch-file" {
        serde_json::from_slice(&std::fs::read(args.get(3).ok_or_else(|| anyhow!("batch JSON file required"))?)?)?
    } else { vec![input_arg.clone()] };
    let started = Instant::now();
    let mut config: t5::Config = serde_json::from_slice(&std::fs::read(root.join("config.json"))?)?;
    config.use_cache = true;
    let mut tokenizer = Tokenizer::from_file(root.join("tokenizer.json")).map_err(|e| anyhow!(e.to_string()))?;
    tokenizer.with_padding(None).with_truncation(None).map_err(|e| anyhow!(e.to_string()))?;
    let device = Device::Cpu;
    let vb = t5::VarBuilder::from_gguf(root.join("model-q4k.gguf"), &device)?;
    let mut model = t5::T5ForConditionalGeneration::load(vb, &config)?;
    let load_seconds = started.elapsed().as_secs_f64();
    for prompt in prompts {
    model.clear_kv_cache();
    let started = Instant::now();
    let input_ids = tokenizer.encode(prompt.as_str(), true).map_err(|e| anyhow!(e.to_string()))?.get_ids().to_vec();
    let encoded_input = tokenizer.decode(&input_ids, false).map_err(|e| anyhow!(e.to_string()))?;
    let input = Tensor::new(input_ids.as_slice(), &device)?.unsqueeze(0)?;
    let encoded = model.encode(&input)?;
    let mut ids = vec![config.decoder_start_token_id.unwrap_or(config.pad_token_id) as u32];
    let mut sampler = LogitsProcessor::new(42, None, None);
    let mut reached_eos = false;
    for index in 0..512 {
        let step = if index == 0 {ids.clone()} else {vec![*ids.last().unwrap()]};
        let decoded = model.decode(&Tensor::new(step.as_slice(), &device)?.unsqueeze(0)?, &encoded)?.squeeze(0)?;
        let token = sampler.sample(&decoded)?;
        if token as usize == config.eos_token_id {reached_eos = true;break;}
        ids.push(token);
    }
    let translation = tokenizer.decode(&ids[1..], true).map_err(|e| anyhow!(e.to_string()))?;
    println!("{}",serde_json::json!({"runtime":"official Candle quantized_t5","device":"Linux CPU; not iOS","model":"original official model-q4k.gguf, no repack","prompt":prompt,"output":translation,"generated_tokens":ids.len()-1,"reached_eos":reached_eos,"wall_seconds":started.elapsed().as_secs_f64(),"sampling":"greedy; no repetition penalty","model_load_seconds":load_seconds,"input_ids":input_ids,"decoded_input":encoded_input}));
    std::io::stdout().flush()?;
    }
    Ok(())
}
