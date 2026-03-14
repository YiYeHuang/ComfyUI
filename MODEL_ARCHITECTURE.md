# 模型架构说明

## 一张图理解全部

```
你写的 prompt → Text Encoder → 数字向量 ┐
                                         ├→ UNET (去噪/生成) → 潜空间结果 → VAE 解码 → 图片/视频
你传的图片   → CLIP Vision → 数字向量  ┘                                     ↑
                             VAE 编码 → 潜空间输入 ──────────────────────────┘
```

## 五种模型

| 模型类型 | 干什么 | 大小 | 例子 |
|----------|--------|------|------|
| **UNET** | 核心大脑，负责在潜空间里去噪/生成 | 大（几GB~几十GB） | `wanVideo22_i2vHighNoise14BFp8Sd.safetensors` |
| **Text Encoder** | 把文字 prompt 翻译成模型能懂的数字向量 | 中（几GB） | `umt5_xxl_fp8_e4m3fn_scaled.safetensors` |
| **CLIP Vision** | 把图片翻译成模型能懂的数字向量（图生图/图生视频用） | 小（1-2GB） | `clip_vision_h.safetensors` |
| **VAE** | 编码器+解码器，图像 ↔ 潜空间的翻译器 | 小（几百MB） | `wan_2.1_vae.safetensors` |
| **LoRA** | UNET 的微调补丁，调整风格/人物 | 很小（几十~几百MB） | Civitai 上下的各种 LoRA |

## Checkpoint vs 分开加载

**Checkpoint** = UNET + Text Encoder + VAE 三合一打包

- 例：`cyberrealisticPony_v160.safetensors`
- 用 `CheckpointLoaderSimple` 一个节点加载，输出 MODEL + CLIP + VAE
- 方便，适合图片生成模型（SD1.5 / SDXL / Pony）

**分开加载** = UNET、Text Encoder、VAE、CLIP Vision 各自独立文件

- 例：Wan Video 需要四个文件分别加载
- 用 `UNETLoader` + `CLIPLoader` + `VAELoader` + `CLIPVisionLoader`
- 视频模型/大模型通常这样做，因为太大打包不现实
- 好处：组件可以被不同模型共用（比如同一个 T5 可以给多个视频模型用）

## 潜空间是什么

图片是 RGB 像素（比如 1024x1024x3），直接在像素空间做生成太慢。

VAE 把图片压缩到一个小得多的「潜空间」（比如 128x128x4），UNET 在这个小空间里工作，完成后 VAE 再解码回像素。这就是为什么叫 Latent Diffusion（潜空间扩散）。

## LoRA 怎么用

LoRA 不是独立模型，是叠在 UNET 上的补丁：

```
CheckpointLoaderSimple → MODEL → LoRA Loader → 调整后的 MODEL → KSampler
                                    ↑
                              LoRA 文件 (models/loras/)
```

- 可以叠多个 LoRA（串联多个 LoRA Loader）
- `strength` 参数控制影响力（0.5-0.8 通常合适，1.0 可能过强）
- LoRA 必须和 UNET 架构匹配：SD1.5 LoRA 配 SD1.5 checkpoint，不能混用

## 当前已有模型

| 文件 | 类型 | 位置 | 用于 |
|------|------|------|------|
| `cyberrealisticPony_v160.safetensors` | Checkpoint (SDXL/Pony) | `models/checkpoints/` | 图片生成/图生图 |
| `wanVideo22_i2vHighNoise14BFp8Sd.safetensors` | UNET | `models/diffusion_models/` | Wan Video 图生视频 |
| `umt5_xxl_fp8_e4m3fn_scaled.safetensors` | Text Encoder (T5) | `models/text_encoders/` | Wan Video 文本理解 |
| `clip_vision_h.safetensors` | CLIP Vision | `models/clip_vision/` | Wan Video 图片理解 |
| `wan_2.1_vae.safetensors` | VAE | `models/vae/` | Wan Video 编解码 |
| `inswapper_128.onnx` | 换脸模型 (ONNX) | `models/insightface/` | ReActor 换脸 |
