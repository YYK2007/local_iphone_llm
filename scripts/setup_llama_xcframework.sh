#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LLAMA_DIR="${LLAMA_DIR:-$ROOT_DIR/.deps/llama.cpp}"
LLAMA_REF="${LLAMA_REF:-master}"

if ! command -v git >/dev/null 2>&1; then
  echo "git is required"
  exit 1
fi

if ! command -v cmake >/dev/null 2>&1; then
  echo "cmake is required (brew install cmake)"
  exit 1
fi

if ! command -v xcrun >/dev/null 2>&1; then
  echo "xcrun is required (install Xcode + command line tools)"
  exit 1
fi

mkdir -p "$(dirname "$LLAMA_DIR")"

if [ ! -d "$LLAMA_DIR/.git" ]; then
  echo "Cloning llama.cpp into $LLAMA_DIR"
  git clone --depth 1 https://github.com/ggml-org/llama.cpp "$LLAMA_DIR"
fi

echo "Fetching llama.cpp ref: $LLAMA_REF"
git -C "$LLAMA_DIR" fetch --depth 1 origin "$LLAMA_REF"
git -C "$LLAMA_DIR" checkout --force FETCH_HEAD

echo "Building llama.xcframework (this can take several minutes)..."
(
  cd "$LLAMA_DIR"
  ./build-xcframework.sh
)

mkdir -p "$ROOT_DIR/build-apple"
rm -rf "$ROOT_DIR/build-apple/llama.xcframework"
cp -R "$LLAMA_DIR/build-apple/llama.xcframework" "$ROOT_DIR/build-apple/llama.xcframework"

echo ""
echo "Done. Framework installed at:"
echo "  $ROOT_DIR/build-apple/llama.xcframework"
echo ""
echo "Next: open qwen_iphone_app/llama.swiftui.xcodeproj in Xcode and run on device."
