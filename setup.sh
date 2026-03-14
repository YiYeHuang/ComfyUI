#!/bin/bash
# ComfyUI Full Setup Script
# For macOS Apple Silicon (M4 Pro / Mac Mini)
# Installs ComfyUI + all custom nodes + dependencies

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== ComfyUI Full Environment Setup ==="
echo ""

# ============================================
# Step 1: System dependencies
# ============================================
echo "=== Step 1: Checking system dependencies ==="

if ! command -v brew &> /dev/null; then
    echo "Error: Homebrew not found. Install from https://brew.sh"
    exit 1
fi

if ! command -v python3.13 &> /dev/null; then
    echo "Installing Python 3.13..."
    brew install python@3.13
fi

if ! command -v uv &> /dev/null; then
    echo "Installing uv..."
    brew install uv
fi

# cmake/protobuf needed by insightface (ReActor dependency)
for pkg in cmake protobuf; do
    if ! brew list "$pkg" &> /dev/null 2>&1; then
        echo "Installing $pkg..."
        brew install "$pkg"
    fi
done

echo "Python: $(python3.13 --version)"
echo "uv: $(uv --version)"
echo ""

# ============================================
# Step 2: Virtual environment
# ============================================
echo "=== Step 2: Setting up virtual environment ==="

if [ -d ".venv" ]; then
    echo ".venv already exists."
    if [ "$1" = "--clean" ]; then
        echo "Recreating (--clean)..."
        rm -rf .venv
        uv venv --python python3.13 .venv
    fi
else
    uv venv --python python3.13 .venv
fi

source .venv/bin/activate
python -m ensurepip --upgrade
python -m pip install --upgrade pip
echo ""

# ============================================
# Step 3: ComfyUI core dependencies
# ============================================
echo "=== Step 3: Installing ComfyUI dependencies ==="
pip install -r requirements.txt
echo ""

# ============================================
# Step 4: Custom nodes (all via SSH)
# ============================================
echo "=== Step 4: Installing custom nodes ==="

cd custom_nodes

declare -A NODES
NODES=(
    ["ComfyUI-Manager"]="git@github.com:Comfy-Org/ComfyUI-Manager.git"
    ["ComfyUI-ReActor"]="git@github.com:Gourieff/ComfyUI-ReActor.git"
    ["ComfyUI-AnimateDiff-Evolved"]="git@github.com:Kosinkadink/ComfyUI-AnimateDiff-Evolved.git"
    ["ComfyUI-VideoHelperSuite"]="git@github.com:Kosinkadink/ComfyUI-VideoHelperSuite.git"
    ["ComfyUI_IPAdapter_plus"]="git@github.com:cubiq/ComfyUI_IPAdapter_plus.git"
    ["ComfyUI-GGUF"]="git@github.com:city96/ComfyUI-GGUF.git"
)

for name in "${!NODES[@]}"; do
    url="${NODES[$name]}"
    if [ -d "$name" ]; then
        echo "  [skip] $name (already exists)"
    else
        echo "  [clone] $name"
        git clone "$url" "$name"
    fi
done

cd "$SCRIPT_DIR"
echo ""

# ============================================
# Step 5: Custom node pip dependencies
# ============================================
echo "=== Step 5: Installing custom node dependencies ==="

# Core deps needed across multiple nodes
pip install opencv-python onnxruntime insightface imageio imageio-ffmpeg

# GGUF support (for Wan 2.2 14B Q4 on Mac MPS)
pip install "gguf>=0.13.0" sentencepiece protobuf

# Install each node's requirements.txt
for d in custom_nodes/*/; do
    if [ -f "$d/requirements.txt" ]; then
        echo "  [pip] $(basename $d)/requirements.txt"
        pip install -r "$d/requirements.txt" 2>&1 | tail -1
    fi
done
echo ""

# ============================================
# Step 6: Create model directories
# ============================================
echo "=== Step 6: Creating model directories ==="

MODEL_DIRS=(
    checkpoints
    diffusion_models
    vae
    text_encoders
    loras
    clip_vision
    ipadapter
    insightface
    animatediff_models
    controlnet
    upscale_models
    latent_upscale_models
)

for dir in "${MODEL_DIRS[@]}"; do
    mkdir -p "models/$dir"
done

echo "  Created ${#MODEL_DIRS[@]} model directories"
echo ""

# ============================================
# Step 7: Verify installation
# ============================================
echo "=== Step 7: Verification ==="
echo "Python:  $(python --version)"
echo "PyTorch: $(python -c 'import torch; print(torch.__version__)')"
echo "Device:  $(python -c 'import torch; print("MPS" if torch.backends.mps.is_available() else "CPU")')"
echo ""

# Verify key dependencies
python -c "
deps = {
    'insightface': 'ReActor',
    'onnxruntime': 'ReActor',
    'cv2': 'ReActor/VideoHelper',
    'imageio': 'VideoHelperSuite',
    'gguf': 'ComfyUI-GGUF',
}
ok, fail = [], []
for mod, node in deps.items():
    try:
        __import__(mod)
        ok.append(f'  [ok] {mod} ({node})')
    except ImportError:
        fail.append(f'  [FAIL] {mod} ({node})')
print('\n'.join(ok + fail))
if fail:
    print(f'\nWARNING: {len(fail)} dependencies failed. Check above.')
else:
    print(f'\nAll {len(ok)} dependencies verified.')
"

echo ""
echo "=== Setup complete ==="
echo ""
echo "Next steps:"
echo "  1. Download models (see TODO.md for full list)"
echo "  2. Copy workflows from user/default/workflows/"
echo "  3. Run: ./start.sh"
echo ""
echo "=== Required models for GGUF Wan 2.2 i2v (Mac) ==="
echo "  diffusion_models/wan2.2_i2v_high_noise_14B_Q4_K_S.gguf  (~8GB)"
echo "  diffusion_models/wan2.2_i2v_low_noise_14B_Q4_K_S.gguf   (~8GB)"
echo "  loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors"
echo "  loras/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors"
echo "  text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
echo "  vae/wan_2.1_vae.safetensors"
