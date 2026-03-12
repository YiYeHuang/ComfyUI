#!/bin/bash
# ComfyUI Environment Setup Script
# Tested on macOS with Apple Silicon (M4 Pro / Mac Mini)

set -e

echo "=== ComfyUI Environment Setup ==="

# Check Python 3.13
if ! command -v python3.13 &> /dev/null; then
    echo "Python 3.13 not found. Installing via Homebrew..."
    if ! command -v brew &> /dev/null; then
        echo "Error: Homebrew not found. Install from https://brew.sh"
        exit 1
    fi
    brew install python@3.13
fi

echo "Python: $(python3.13 --version)"

# Check uv
if ! command -v uv &> /dev/null; then
    echo "uv not found. Installing..."
    brew install uv
fi

echo "uv: $(uv --version)"

# Create virtual environment
echo ""
echo "=== Creating virtual environment ==="
if [ -d ".venv" ]; then
    echo ".venv already exists. Use --clean to recreate."
    if [ "$1" = "--clean" ]; then
        rm -rf .venv
        uv venv --python python3.13 .venv
    fi
else
    uv venv --python python3.13 .venv
fi

# Activate and install dependencies
echo ""
echo "=== Installing dependencies ==="
source .venv/bin/activate
python -m ensurepip --upgrade
python -m pip install --upgrade pip
python -m pip install -r requirements.txt

echo ""
echo "=== Setup complete ==="
echo "Python: $(python --version)"
echo "PyTorch: $(python -c 'import torch; print(torch.__version__)')"
echo "Device: $(python -c 'import torch; print("MPS" if torch.backends.mps.is_available() else "CPU")')"
echo ""
echo "To start ComfyUI, run: ./start.sh"
