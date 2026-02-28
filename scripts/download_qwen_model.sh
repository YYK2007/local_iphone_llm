#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${OUT_DIR:-$ROOT_DIR/models}"
MODEL_KEY="${1:-qwen3-1.7b-q4km}"

mkdir -p "$OUT_DIR"

case "$MODEL_KEY" in
  qwen3-1.7b-q4_0)
    FILENAME="Qwen3-1.7B-Q4_0.gguf"
    URL="https://huggingface.co/ggml-org/Qwen3-1.7B-GGUF/resolve/main/Qwen3-1.7B-Q4_0.gguf?download=true"
    ;;
  qwen3-1.7b-q4km)
    FILENAME="Qwen3-1.7B-Q4_K_M.gguf"
    URL="https://huggingface.co/ggml-org/Qwen3-1.7B-GGUF/resolve/main/Qwen3-1.7B-Q4_K_M.gguf?download=true"
    ;;
  qwen3-4b-q4_0)
    FILENAME="Qwen3-4B-Q4_0.gguf"
    URL="https://huggingface.co/ggml-org/Qwen3-4B-GGUF/resolve/main/Qwen3-4B-Q4_0.gguf?download=true"
    ;;
  qwen3-4b-q4km)
    FILENAME="Qwen3-4B-Q4_K_M.gguf"
    URL="https://huggingface.co/ggml-org/Qwen3-4B-GGUF/resolve/main/Qwen3-4B-Q4_K_M.gguf?download=true"
    ;;
  *)
    echo "Unknown model key: $MODEL_KEY"
    echo "Valid keys:"
    echo "  qwen3-1.7b-q4_0"
    echo "  qwen3-1.7b-q4km"
    echo "  qwen3-4b-q4_0"
    echo "  qwen3-4b-q4km"
    exit 1
    ;;
esac

echo "Downloading $MODEL_KEY"
echo "URL: $URL"

curl -L "$URL" -o "$OUT_DIR/$FILENAME"

echo ""
echo "Saved model to: $OUT_DIR/$FILENAME"
