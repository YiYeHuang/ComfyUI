# 本地生成功能搭建指南

环境：macOS Apple Silicon, 48GB RAM, MPS, PyTorch 2.7, **Python 3.13**

---

## 零、Python 3.13 兼容性警告

当前环境是 Python 3.13，部分插件的依赖（特别是 `insightface`、`onnxruntime`）对 3.13 支持可能有问题。

**如果安装过程中遇到编译失败，备选方案：**

```bash
# 用 Python 3.11 单独建一个 venv（最稳定的版本）
brew install python@3.11
uv venv --python python3.11 .venv311
source .venv311/bin/activate
pip install -r requirements.txt
# 然后在这个 venv 里装插件依赖
```

先用 3.13 试，不行再降。

---

## 一、需要安装的插件 + 依赖

**重要：所有 pip install 都要在 venv 里操作。**

```bash
cd /Users/yiyehuang/Desktop/myworkspace/ComfyUI
source .venv/bin/activate
```

### 1. ReActor — 换脸（图片+视频）

```bash
# 1a. 先装系统依赖
brew install cmake protobuf

# 1b. 先装 Python 依赖（不要等 requirements.txt，手动装更可控）
pip install opencv-python
pip install onnxruntime           # Mac 不需要 onnxruntime-gpu
pip install insightface

# 1c. Clone 插件
cd custom_nodes
git clone https://github.com/Gourieff/ComfyUI-ReActor
cd ComfyUI-ReActor
pip install -r requirements.txt   # 大部分已装好，这步补漏
cd ../..
```

**验证：**
```bash
python -c "import insightface; import onnxruntime; import cv2; print('ReActor deps OK')"
```

如果 `insightface` 装不上（Python 3.13 编译失败），试：
```bash
pip install insightface --no-build-isolation
# 或者
pip install cython numpy && pip install insightface
```

### 2. AnimateDiff — 图生视频

```bash
cd custom_nodes
git clone https://github.com/Kosinkadink/ComfyUI-AnimateDiff-Evolved
cd ../..
```

无额外 pip 依赖，ComfyUI 自带的 torch/transformers/safetensors 够用。

### 3. VideoHelperSuite — 视频加载/拆帧/合成

```bash
pip install imageio imageio-ffmpeg

cd custom_nodes
git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite
cd ComfyUI-VideoHelperSuite
pip install -r requirements.txt
cd ../..
```

**验证：**
```bash
python -c "import imageio; print('imageio OK')"
```

### 4. (可选) ComfyUI-Manager — 插件管理器

```bash
cd custom_nodes
git clone https://github.com/ltdrdata/ComfyUI-Manager
cd ../..
```

之后启动时加 `--enable-manager`，可以在 UI 里搜索安装其他插件。

---

## 二、需要手动安装的 pip 依赖汇总

如果不想一步步来，可以一次性装：

```bash
source .venv/bin/activate
pip install opencv-python onnxruntime insightface imageio imageio-ffmpeg
```

**当前环境已有（不用装）：** torch, numpy, pillow, safetensors, scipy, tqdm, transformers, av

**缺少（必须装）：**

| 包 | 被谁需要 | 说明 |
|---|---------|------|
| `opencv-python` | ReActor | 图像处理 |
| `onnxruntime` | ReActor | 换脸模型推理 |
| `insightface` | ReActor | 人脸检测/分析 |
| `imageio` | VideoHelperSuite | 视频 I/O |
| `imageio-ffmpeg` | VideoHelperSuite | ffmpeg 后端 |

---

## 三、需要下载的模型

### 基础模型（Checkpoint）

放到 `models/checkpoints/`

| 模型 | 说明 | 来源 |
|------|------|------|
| RealisticVision V5.1 | 真人写实，换脸效果好 | Civitai 搜 "Realistic Vision" |
| MajicMix Realistic | 亚洲面孔更自然 | Civitai 搜 "majicmixRealistic" |
| DreamShaper | 通用型，平衡写实和艺术 | Civitai 搜 "DreamShaper" |

建议先下一个就行，推荐 RealisticVision 或 MajicMix。都是 SD1.5 架构，48GB 很轻松。

### 换脸模型

```bash
mkdir -p models/insightface
```

| 模型 | 放到 | 来源 |
|------|------|------|
| `inswapper_128.onnx` | `models/insightface/` | HuggingFace 搜 "inswapper_128" 或 GitHub facefusion-assets releases |

这个是 ReActor 的核心，必装。约 500MB。

### AnimateDiff Motion Module

```bash
mkdir -p models/animatediff_models
```

| 模型 | 放到 | 来源 |
|------|------|------|
| `mm_sd15_v3.safetensors` | `models/animatediff_models/` | HuggingFace: guoyww/animatediff-motion-adapter-v1-5-3 |

### LoRA（按需）

放到 `models/loras/`。Civitai 上按需搜。注意 LoRA 要和 checkpoint 架构匹配（SD1.5 配 SD1.5）。

---

## 四、安装步骤总结

```bash
# === 进入项目，激活 venv ===
cd /Users/yiyehuang/Desktop/myworkspace/ComfyUI
source .venv/bin/activate

# === Step 1: 系统依赖 ===
brew install cmake protobuf

# === Step 2: Python 依赖 ===
pip install opencv-python onnxruntime insightface imageio imageio-ffmpeg

# === Step 3: 验证 ===
python -c "import insightface, onnxruntime, cv2, imageio; print('ALL OK')"
# 如果这步失败，看上面的 Python 3.13 兼容性说明

# === Step 4: Clone 插件 ===
cd custom_nodes
git clone https://github.com/Gourieff/comfyui-reactor-node
git clone https://github.com/Kosinkadink/ComfyUI-AnimateDiff-Evolved
git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite
git clone https://github.com/ltdrdata/ComfyUI-Manager
cd ..

# === Step 5: 插件自己的依赖（补漏） ===
cd custom_nodes/ComfyUI-ReActor && pip install -r requirements.txt && cd ../..
cd custom_nodes/ComfyUI-VideoHelperSuite && pip install -r requirements.txt && cd ../..

# === Step 6: 创建模型目录 ===
mkdir -p models/insightface models/animatediff_models

# === Step 7: 下载模型（手动） ===
# - inswapper_128.onnx → models/insightface/
# - SD1.5 checkpoint → models/checkpoints/
# - mm_sd15_v3.safetensors → models/animatediff_models/

# === Step 8: 启动验证 ===
./start.sh --enable-manager
```

---

## 五、功能对应的工作流

### A. 图片换脸

```
LoadImage (源脸照片)
        ↘
         ReActor Face Swap ──→ PreviewImage
        ↗
LoadImage (目标图片)
```

### B. 图生视频（AnimateDiff）

```
Load Checkpoint ──→ KSampler ──→ VAE Decode ──→ Video Combine
                        ↑
               AnimateDiff Loader
                        ↑
              Motion Module (mm_sd15_v3)
```

img2vid：在 KSampler 前加 `Load Image → VAE Encode` 作为初始 latent。

### C. 视频换脸

```
Load Video (VHS) ──→ ReActor Face Swap ──→ Video Combine
                           ↑
                    LoadImage (源脸)
```

VideoHelperSuite 的 `Load Video` 自动拆帧，ReActor 支持 batch，直接串起来。

---

## 六、验证安装

启动后在浏览器里右键空白处 → Add Node，检查：
- `ReActor` 分类下有 `ReActorFaceSwap` 节点
- `AnimateDiff` 分类下有相关节点
- `Video Helper Suite` 分类下有 `Load Video` / `Video Combine`

如果某个分类不存在，看终端报错，通常是 pip 依赖没装全。

---

## 七、性能预期

| 功能 | 48GB Apple Silicon 预期 |
|------|------------------------|
| 图片换脸 | 几秒 |
| SD1.5 出图 (512x512) | 10-20秒 |
| AnimateDiff 16帧 | 1-3分钟 |
| 视频换脸 (30帧) | 1-2分钟 |
| SDXL 出图 (1024x1024) | 30-60秒 |

---

## 八、Civitai 淘货建议

- 下载时注意看模型架构标签：`SD 1.5` / `SDXL` / `Flux`，别混用
- 模型页面通常有示例 workflow，可以直接下载 JSON 导入 ComfyUI
- 排序用 "Most Downloaded" 或 "Highest Rated" 找稳定的模型
- 看评论区，有人会报告哪些 LoRA 搭配效果好
