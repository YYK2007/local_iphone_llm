# Posting Guide: Qwen on iPhone

Use this checklist when posting benchmarks/videos so your results are reproducible and credible.

## Always report
- iPhone model + iOS version
- Xcode version
- `llama.cpp` ref used for `llama.xcframework`
- model filename + quantization
- runtime defaults:
  - `n_ctx = 2048`
  - `max new tokens = 512`
- whether prompt used `/no_think` or `/think`

## Suggested benchmark protocol
1. Close heavy background apps.
2. Launch app, load one model, wait until fully loaded.
3. Run one warmup query.
4. Run benchmark 3 times.
5. Report mean and spread for:
   - prompt processing (`pp` tokens/sec)
   - generation (`tg` tokens/sec)

## Fair-comparison rules
- Same quantization across devices.
- Same context settings.
- Same prompt length.
- Clearly separate local on-device inference from cloud/API inference.

## Suggested caption language
"Full on-device inference on iPhone using llama.cpp + Metal with Qwen GGUF."
