# Qwen iPhone Chat (On-Device, Xcode)

Run Qwen GGUF models locally on iPhone using `llama.cpp` + Metal, with a polished chat UI, persistent conversation threads, memory, and theme customization.

## What this project includes
- iOS app (`llama.swiftui` based) customized for Qwen GGUF models
- Persistent multi-turn chat threads
- Global + per-thread memory notes (`/remember`, `/memory`)
- Markdown-style response rendering (headings, lists, code, quotes, emphasis)
- Collapsible `<think>` handling in UI
- Black/gold default theme with full color customization
- Reliability guards for empty-output turns (multi-pass + deterministic retry)

## Reality check on Qwen3.5
This app is optimized for local Qwen3 GGUF models that fit phone memory budgets.
Very large Qwen3.5 classes are generally not practical for full local iPhone inference today.

## Recommended local models
- `Qwen3-1.7B-Q4_K_M.gguf` (best starting point)
- `Qwen3-4B-Q4_0.gguf` (higher quality, heavier)

## Prerequisites
- macOS with Xcode + Command Line Tools
- Apple Developer signing configured in Xcode
- A physical iPhone (recommended for real performance)

## 1) Build `llama.xcframework`
```bash
./scripts/setup_llama_xcframework.sh
```

Expected output path:
- `build-apple/llama.xcframework`

## 2) Open and run on iPhone
1. Open `qwen_iphone_app/llama.swiftui.xcodeproj`
2. Set your Team and a unique bundle id (for example `com.yourname.qweniphone`)
3. Select your iPhone device target
4. Build and run

## 3) Load a model
From the app, use one of:
- Built-in recommended model list
- Custom GGUF URL download
- Import `.gguf` from Files

Suggested first run:
- `Qwen3-1.7B-Q4_K_M.gguf`

## Chat commands
- `/remember <fact>`: save a memory note
- `/memory`: display stored memory notes
- `/think`: allow reasoning output
- `/no_think`: prefer direct answer output

## Current runtime defaults
- Context window (`n_ctx`): `2048`
- Max new tokens per reply: `512`
- iOS target in project: `16.4`

## Repository layout
- `qwen_iphone_app/`: iOS app source
- `scripts/setup_llama_xcframework.sh`: build and install runtime framework
- `scripts/download_qwen_model.sh`: optional CLI GGUF downloader
- `docs/POSTING_GUIDE.md`: benchmark/reporting template
- `docs/GITHUB_PUBLISH.md`: steps to publish this repo to GitHub

## License and attributions
- This repo: MIT (see `LICENSE`)
- Runtime/model dependencies keep their own upstream licenses (see `NOTICE.md`)
