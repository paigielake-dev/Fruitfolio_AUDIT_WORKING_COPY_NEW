//! Local official MADLAD adapter. Caller owns each handle and serializes access.
//! This ABI is a compatibility candidate, not approval to enable medical translation.
use std::{ffi::{CStr,CString,c_char},path::PathBuf,panic::{catch_unwind,AssertUnwindSafe}};
use candle_core::{Device,Tensor};
use candle_transformers::{models::quantized_t5 as t5,generation::LogitsProcessor};
use tokenizers::Tokenizer;
struct Runtime { model:t5::T5ForConditionalGeneration, tokenizer:Tokenizer, config:t5::Config }
unsafe fn string(p:*const c_char)->Result<String,String>{
 if p.is_null(){return Err("null input".into())}
 unsafe{CStr::from_ptr(p)}.to_str().map(str::to_owned).map_err(|e|e.to_string())
}
fn output(s:String)->*mut c_char {CString::new(s).map(CString::into_raw).unwrap_or(std::ptr::null_mut())}
#[no_mangle]
pub unsafe extern "C" fn fruitfolio_madlad_open(root:*const c_char,error:*mut *mut c_char)->*mut std::ffi::c_void {
 let result=catch_unwind(AssertUnwindSafe(||->Result<Runtime,String>{
  let root=PathBuf::from(unsafe{string(root)}?);
  let mut config:t5::Config=serde_json::from_slice(&std::fs::read(root.join("config.json")).map_err(|e|e.to_string())?).map_err(|e|e.to_string())?;
  config.use_cache=true;
  let mut tokenizer=Tokenizer::from_file(root.join("tokenizer.json")).map_err(|e|e.to_string())?;
  tokenizer.with_padding(None).with_truncation(None).map_err(|e|e.to_string())?;
  let vb=t5::VarBuilder::from_gguf(root.join("model-q4k.gguf"),&Device::Cpu).map_err(|e|e.to_string())?;
  let model=t5::T5ForConditionalGeneration::load(vb,&config).map_err(|e|e.to_string())?;
  Ok(Runtime{model,tokenizer,config})
 }));
 match result {
  Ok(Ok(runtime))=>Box::into_raw(Box::new(runtime)).cast(),
  failure=>{if !error.is_null(){unsafe{*error=output(match failure{Ok(Err(e))=>e,_=>"runtime initialization panicked".into()})}};std::ptr::null_mut()}
 }
}
#[no_mangle]
pub unsafe extern "C" fn fruitfolio_madlad_translate(handle:*mut std::ffi::c_void,prompt:*const c_char)->*mut c_char {
 let result=catch_unwind(AssertUnwindSafe(||->Result<String,String>{
  if handle.is_null(){return Err("runtime unavailable".into())}
  let runtime=unsafe{&mut *handle.cast::<Runtime>()};
  let prompt=unsafe{string(prompt)}?;
  if prompt.len()>8192{return Err("input exceeds bounded translation size".into())}
  runtime.model.clear_kv_cache();
  let ids=runtime.tokenizer.encode(prompt,true).map_err(|e|e.to_string())?.get_ids().to_vec();
  if ids.len()>512{return Err("input exceeds model position budget".into())}
  let input=Tensor::new(ids.as_slice(),&Device::Cpu).and_then(|x|x.unsqueeze(0)).map_err(|e|e.to_string())?;
  let encoded=runtime.model.encode(&input).map_err(|e|e.to_string())?;
  let mut ids=vec![runtime.config.decoder_start_token_id.unwrap_or(runtime.config.pad_token_id) as u32];
  let mut sampler=LogitsProcessor::new(42,None,None);
  for index in 0..512 {
   let step=if index==0{ids.clone()}else{vec![*ids.last().unwrap()]};
   let input=Tensor::new(step.as_slice(),&Device::Cpu).and_then(|x|x.unsqueeze(0)).map_err(|e|e.to_string())?;
   let logits=runtime.model.decode(&input,&encoded).and_then(|x|x.squeeze(0)).map_err(|e|e.to_string())?;
   let token=sampler.sample(&logits).map_err(|e|e.to_string())?;
   if token as usize==runtime.config.eos_token_id{
    return runtime.tokenizer.decode(&ids[1..],true).map_err(|e|e.to_string())
   }
   ids.push(token);
  }
  Err("output did not reach EOS; partial translation rejected".into())
 }));
 output(match result{Ok(Ok(text))=>serde_json::json!({"ok":true,"text":text}).to_string(),Ok(Err(error))=>serde_json::json!({"ok":false,"error":error}).to_string(),Err(_)=>serde_json::json!({"ok":false,"error":"translation panicked"}).to_string()})
}
#[no_mangle]
pub unsafe extern "C" fn fruitfolio_madlad_close(handle:*mut std::ffi::c_void){if !handle.is_null(){unsafe{drop(Box::from_raw(handle.cast::<Runtime>()))}}}
#[no_mangle]
pub unsafe extern "C" fn fruitfolio_madlad_free_string(value:*mut c_char){if !value.is_null(){unsafe{drop(CString::from_raw(value))}}}
