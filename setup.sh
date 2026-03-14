#!/bin/bash
# ComfyUI Setup Script for macOS Apple Silicon
# Usage: ./setup.sh [--clean]

set -e
cd "$(dirname "$0")"

# ============================================
# 1. 基础环境
# ============================================
echo "=== 1. 基础环境 ==="

# 系统依赖 (brew)
brew install python@3.13 uv cmake protobuf 2>/dev/null || true

# 虚拟环境
if [ ! -d ".venv" ] || [ "$1" = "--clean" ]; then
    rm -rf .venv
    uv venv --python python3.13 .venv
fi

source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# ============================================
# 2. Custom Nodes (全部 SSH clone)
# ============================================
echo "=== 2. Custom Nodes ==="
cd custom_nodes

# ComfyUI-Manager — 插件管理器 UI
[ ! -d "ComfyUI-Manager" ] && \
    git clone git@github.com:Comfy-Org/ComfyUI-Manager.git
pip install -r ComfyUI-Manager/requirements.txt

# ComfyUI-ReActor — 换脸 (图片+视频)
[ ! -d "ComfyUI-ReActor" ] && \
    git clone git@github.com:Gourieff/ComfyUI-ReActor.git
# matplotlib 3.9 在 Python 3.13 上编译失败，先装新版绕过
pip install "matplotlib>=3.10.0" --only-binary=:all:
pip install opencv-python onnxruntime insightface
pip install -r ComfyUI-ReActor/requirements.txt

# ComfyUI_IPAdapter_plus — 参考图风格/人脸迁移
[ ! -d "ComfyUI_IPAdapter_plus" ] && \
    git clone git@github.com:cubiq/ComfyUI_IPAdapter_plus.git

# ComfyUI-AnimateDiff-Evolved — SD1.5 图生视频
[ ! -d "ComfyUI-AnimateDiff-Evolved" ] && \
    git clone git@github.com:Kosinkadink/ComfyUI-AnimateDiff-Evolved.git

# ComfyUI-VideoHelperSuite — 视频加载/拆帧/合成
[ ! -d "ComfyUI-VideoHelperSuite" ] && \
    git clone git@github.com:Kosinkadink/ComfyUI-VideoHelperSuite.git
pip install -r ComfyUI-VideoHelperSuite/requirements.txt

# ComfyUI-GGUF — GGUF 量化模型加载 (Mac 跑 Wan 14B 必备)
[ ! -d "ComfyUI-GGUF" ] && \
    git clone git@github.com:city96/ComfyUI-GGUF.git
pip install -r ComfyUI-GGUF/requirements.txt

cd ..

# ============================================
# 3. 模型目录
# ============================================
echo "=== 3. 模型目录 ==="
mkdir -p models/{checkpoints,diffusion_models,vae,text_encoders,loras,clip_vision,ipadapter,insightface,animatediff_models,controlnet,upscale_models,latent_upscale_models}

# ============================================
# 4. 验证
# ============================================
echo "=== 4. 验证 ==="
python -c "
for mod, use in [
    ('torch', 'PyTorch'),
    ('insightface', 'ReActor'),
    ('onnxruntime', 'ReActor'),
    ('cv2', 'ReActor/VideoHelper'),
    ('imageio', 'VideoHelperSuite'),
    ('gguf', 'ComfyUI-GGUF'),
]:
    try:
        __import__(mod)
        print(f'  [ok] {mod} ({use})')
    except:
        print(f'  [FAIL] {mod} ({use})')

import torch
print(f'\n  PyTorch {torch.__version__}')
print(f'  MPS: {torch.backends.mps.is_available()}')
"

echo ""
echo "=== Done. Run ./start.sh to launch ==="
