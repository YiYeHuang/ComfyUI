# Feature Progress

## Custom Gemini Local Nodes

**File:** `custom_nodes/gemini_local.py`
**API Bridge:** `http://localhost:11211/api/gemini`（无需 API key，bridge 已处理认证）

### Nodes

#### 1. Gemini Local Chat
- **用途：** 文本对话 + 图片理解
- **输入：**
  - `model` — 文本模型选择（gemini-3.1-pro-preview, gemini-2.5-pro, gemini-2.5-flash 等 9 个）
  - `prompt` — 用户请求内容
  - `image`（可选）— 图片理解，传入图片后可问关于图片的问题
  - `system_prompt`（可选）— 设定 AI 角色/规则
  - `temperature` — 创造性（0-2，默认 1.0）
  - `top_p` — 核采样阈值（0-1，默认 0.95）
  - `top_k` — Top-K 采样（1-100，默认 40）
  - `max_tokens` — 最大输出 token 数（默认 2048）
  - `seed` — 随机种子，支持 control_after_generate
- **输出：** `text`

#### 2. Gemini Local Image Gen
- **用途：** 文生图 / 图生图
- **输入：**
  - `model` — 图片模型选择（gemini-3.1-flash-image-preview, gemini-2.5-flash-image）
  - `prompt` — 图片描述
  - `reference_image`（可选）— 参考图，用于图生图
  - `system_prompt`（可选）— 风格控制
  - `temperature`, `top_p`, `top_k`, `seed`
- **输出：** `image`, `text`

#### 3. Gemini Local Image Edit
- **用途：** 图片编辑，支持多参考图
- **输入：**
  - `model` — 图片模型选择
  - `image` — 要编辑的主图（必填）
  - `instruction` — 编辑指令（如 "Remove the background and replace it with a sunset"）
  - `references`（可选）— 参考图 batch，用 Batch Images 节点组合多张图传入
  - `mask`（可选）— 遮罩，白色=要编辑区域，黑色=保留区域
  - `temperature`, `seed`
- **输出：** `image`, `text`

#### 4. Veo Local Video Gen
- **用途：** 文生视频 / 图生视频 / 图到图转场
- **输入：**
  - `model` — Veo 模型选择（veo-3.1, veo-3.0, veo-2.0，含 fast 版本）
  - `prompt` — 视频描述
  - `start_frame`（可选）— 起始帧
  - `end_frame`（可选）— 结束帧，与 start_frame 配合做转场
  - `duration` — 4/6/8 秒
  - `aspect_ratio` — 16:9, 9:16, 1:1
  - `negative_prompt`（可选）— 不想要的元素
  - `seed`, `poll_interval`
- **输出：** `video_path`（保存在 output/），`first_frame`，`last_frame`（用于连续视频链），`status`
- **注意：** 视频生成需要 1-3 分钟，节点会自动轮询等待

### 多图参考用法示例

#### 基础：单张参考图编辑
```
Load Image (人物照) → [image]  Gemini Local Image Edit → Preview Image
                               [instruction]: "Change the background to a beach"
```

#### 进阶：人物 + 多衣物部件合成（推荐：逐步串联法）

**场景：** 你有一张人物舞蹈照，想给她穿上指定的帽子、上衣、裙子、鞋子。

**推荐方案：一步一件，逐步叠加。** 每步只改一个部件，可以在每步之间用 Preview Image 检查效果，不满意就调整该步的 instruction/seed，不用全部重来。

**节点连接：**
```
Load Image (舞者原图)
    │
    ▼
GeminiLocalImageEdit ①  ←── Load Image (帽子素材) → [references]
  [instruction]: "Put this hat on the dancer.
   Keep her face, pose and body exactly the same."
    │
    ├──→ Preview Image ① （检查帽子效果）
    │
    ▼
GeminiLocalImageEdit ②  ←── Load Image (上衣素材) → [references]
  [instruction]: "Dress the dancer in this top.
   Keep everything else unchanged."
    │
    ├──→ Preview Image ② （检查上衣效果）
    │
    ▼
GeminiLocalImageEdit ③  ←── Load Image (裙子素材) → [references]
  [instruction]: "Change the dancer's bottom to this skirt.
   Keep everything else unchanged."
    │
    ├──→ Preview Image ③ （检查裙子效果）
    │
    ▼
GeminiLocalImageEdit ④  ←── Load Image (鞋子素材) → [references]
  [instruction]: "Add these shoes to the dancer.
   Keep everything else unchanged."
    │
    ▼
Preview Image ④ （最终效果）
```

**操作步骤：**
1. 拖出 1 个 Load Image（舞者原图）+ 4 个 Load Image（衣物素材）
2. 拖出 4 个 GeminiLocalImageEdit，串联起来：
   - 舞者原图 → Edit① 的 `image`
   - Edit① 的 `image` 输出 → Edit② 的 `image` 输入
   - Edit② → Edit③ → Edit④，依次串联
3. 每个 Edit 节点的 `references` 分别接对应的衣物 Load Image
4. 每个 Edit 节点后面接一个 Preview Image 查看中间结果
5. 用 **Run (on change)** 模式，改哪步的参数就只重跑那步及之后的步骤（缓存机制）

**优势：**
- 每步任务单一明确，Gemini 成功率更高
- 中间结果可视化，问题定位容易
- 利用缓存机制，改某一步不用从头跑
- 每步可以单独调 seed/temperature/instruction

**Instruction 写法技巧：**
- 每步只描述一个改动，不要贪多
- 强调保留其他部分："Keep everything else unchanged"
- 如果效果不好，试试降低 temperature（0.5-0.8）
- 可以加风格要求："Make it look natural and photorealistic"

#### 进阶：用 mask 精确控制编辑区域

**场景：** 只想换上半身衣服，不动其他部分。

```
Load Image (舞者原图) ────→ [image]
Load Image (上衣素材) ────→ [references]（不需要 Batch，单张直接连）
Load Image (上半身白色遮罩) → [mask]
                               │
                   Gemini Local Image Edit
                   [instruction]: "Replace the dancer's top with
                    the clothing from the reference image"
```

mask 制作方式：用任意图片编辑器（PS/GIMP/预览），把要编辑的区域涂白，其余涂黑，导出为 PNG。

#### 视频转场

**场景：** 从一张图平滑过渡到另一张图。

```
Load Image (场景A) ──→ [start_frame]
                                        VeoLocalVideoGen ──→ output/xxx.mp4
Load Image (场景B) ──→ [end_frame]
                         prompt: "cinematic smooth transition"
```

也可以串联图片生成 + 视频：
```
GeminiLocalImageGen ──→ [start_frame]
  "a dancer in red"                     VeoLocalVideoGen ──→ video
GeminiLocalImageGen ──→ [end_frame]
  "a dancer in blue"       prompt: "the dancer spins and outfit transforms"
```

### 可用模型列表（来自 bridge）

**文本模型：**
- gemini-3.1-pro-preview
- gemini-3-pro-preview
- gemini-3.1-flash-lite-preview
- gemini-3-flash-preview
- gemini-2.5-pro
- gemini-2.5-flash
- gemini-2.5-flash-lite
- gemini-2.0-flash-001
- gemini-2.0-flash-lite-001

**图片生成模型：**
- gemini-3.1-flash-image-preview
- gemini-2.5-flash-image

**视频生成模型：**
- veo-3.1-generate-001 / veo-3.1-fast-generate-001
- veo-3.0-generate-001 / veo-3.0-fast-generate-001
- veo-2.0-generate-001

### 已知限制

- Gemini 图片生成受 Google 服务端内容安全过滤，敏感内容会返回黑图（64x64），text 输出会有错误信息
- API 不稳定时会自动重试 3 次（间隔 2 秒），重试日志输出到终端
- 同一 seed + 同一 prompt 只是「尽力」一致，不保证完全相同
- 人物一致性保持能力有限，严格一致性需要本地模型（IP-Adapter / InstantID）
- 视频生成需要 1-3 分钟等待
- **本地模型无内容限制**，完全取决于模型训练数据

---

## 部署

### 前提条件
- macOS (Apple Silicon)
- Homebrew
- Python 3.13（`brew install python@3.13`）
- uv 包管理器（`brew install uv`）
- Gemini API bridge 运行在 `http://localhost:11211/api/gemini`

### 新机器部署（如 Mac Mini）

```bash
# 1. Clone 代码
git clone <repo-url>
cd ComfyUI

# 2. 一键配置环境
./setup.sh

# 3. 启动
./start.sh
```

### 脚本说明

| 脚本 | 用途 |
|------|------|
| `setup.sh` | 环境配置：创建 .venv、安装 Python 依赖。加 `--clean` 重建虚拟环境 |
| `start.sh` | 启动 ComfyUI 服务器，默认 http://127.0.0.1:8188 |

### start.sh 参数

```bash
./start.sh              # 默认：localhost:8188
./start.sh --lan        # 局域网可访问（0.0.0.0:8188）
./start.sh --port 9999  # 自定义端口
./start.sh --cpu        # 强制 CPU 模式（一般不需要，Apple Silicon 自动用 MPS）
```

### setup.sh 做了什么

1. 检查 Python 3.13，没有就 `brew install python@3.13`
2. 检查 uv，没有就 `brew install uv`
3. `uv venv --python python3.13 .venv` 创建虚拟环境
4. `python -m ensurepip` 引导 pip
5. `pip install -r requirements.txt` 安装所有依赖（PyTorch、transformers、aiohttp 等）
6. 验证 PyTorch 和 MPS（Apple GPU 加速）可用
