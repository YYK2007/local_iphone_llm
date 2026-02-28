# iOS App: Qwen Chat on iPhone

This directory contains the Xcode iOS app customized from `llama.cpp/examples/llama.swiftui`.

## Key app features
- Qwen GGUF model support
- Persistent chat threads with memory
- Automatic memory capture for common user facts
- Collapsible reasoning blocks (`<think> ... </think>`)
- Markdown-style rendering for lists/code/headings/emphasis
- Black/gold base theme + full theme customization
- Retry pipeline for empty generations (including deterministic fallback)

## Build prerequisite
From repository root:

```bash
./scripts/setup_llama_xcframework.sh
```

The app expects:
- `../build-apple/llama.xcframework`

## Run on iPhone
1. Open `llama.swiftui.xcodeproj`
2. Set Team + Bundle Identifier
3. Select physical iPhone device
4. Build and run

## Default runtime configuration
- `n_ctx = 2048`
- `maxNewTokens = 512`

## Notes
- If you use Qwen3 models, ensure your `llama.xcframework` is recent enough to support `qwen3` architecture.
- For best responsiveness, start with `Qwen3-1.7B-Q4_K_M.gguf`.
