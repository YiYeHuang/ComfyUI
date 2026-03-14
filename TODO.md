# ComfyUI 待办清单

## 优先级排序

### 1. 优化画质（高优先）
- [x] ~~下载 Flux.1 Dev 模型~~ → 放弃，Mac MPS 上太慢太糊
- [x] 安装 IPAdapter Plus 插件（`cubiq/ComfyUI_IPAdapter_plus`）
- [x] 下载 IPAdapter 模型（plus-face + plus，SDXL ViT-H）
- [ ] 下载写实 SDXL checkpoint（RealVisXL / JuggernautXL）替代 Pony 油腻感
- [ ] IPAdapter + 写实 SDXL 验证效果
- [ ] 研究 ControlNet（精确控制姿势/构图，解决多腿问题）

### 2. 稳定多人出图（中高优先）
- [x] IPAdapter RegionalConditioning workflow 已搭建（ipadapter_2person.json）
- [ ] 测试两人合一图效果，调 mask 比例和 weight
- [ ] 研究 ControlNet OpenPose 做多人姿势控制

### 3. ~~Local Gemini 连续出视频~~（已完成）
- [x] 修改 VeoLocalVideoGen 节点，新增 last_frame 输出
- [x] 做 workflow：Veo 出视频 → last_frame → 下一段 Veo（veo_continuous_video.json）
- [x] 支持 fix seed 跳过已成功的段落，只重跑失败的
- [x] Veo 失败时增加 full response logging（排查内容过滤）

### 4. 视频换脸（中优先）
- [ ] 已有工具：ReActor + VideoHelperSuite
- [ ] 做 workflow：Load Video → 拆帧 → ReActor 逐帧换脸 → Video Combine
- [ ] 研究帧间脸部一致性问题（不同帧换脸结果可能不一致）

### 5. 本地视频生成（中高优先 — GGUF 方案可行）
- [x] Wan 2.2 5B fp16 下载配置 → ❌ fp8/fp16 在 MPS 上数值出错，输出花屏
- [x] 确认问题：MPS 不支持 fp8 运算，text encoder 和 diffusion model 都受影响
- [ ] **GGUF Q4 方案（M3 Max 36GB 已验证可行）：**
  - [ ] 安装 ComfyUI-GGUF 自定义节点：`cd custom_nodes && git clone https://github.com/city96/ComfyUI-GGUF`
  - [ ] 下载 `wan2.2_i2v_high_noise_14B_Q4_K_S.gguf` (~8GB) → `models/diffusion_models/`
  - [ ] 下载 `wan2.2_i2v_low_noise_14B_Q4_K_S.gguf` (~8GB) → `models/diffusion_models/`
  - [ ] 来源：`huggingface.co/bullerwins/Wan2.2-I2V-A14B-GGUF`
  - [ ] 下载 `wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors` (~400MB) → `models/loras/`
  - [ ] 下载 `wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors` (~400MB) → `models/loras/`
  - [ ] 来源：`huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/tree/main/split_files/loras`
  - [ ] 保存 GGUF i2v workflow（双模型两阶段采样 + 4步LoRA加速）
  - [ ] 测试验证（预计 M4 Pro 48GB：240x240 ~3min, 360x360 ~7min）
- [ ] Wan 2.2 Fun Control 5B（自带 ControlNet 姿势控制）— 待 GGUF 方案验证后再看

### 6. ReActor 换脸强化（已完成基础）
- [x] FaceBoost + RestoreFaceAdvanced workflow（local_face_swap_boost.json）
- [ ] SaveFaceModel / BuildFaceModel — 多角度融合人脸模型，提升一致性

---

## 当前已完成

- [x] ComfyUI 基础环境搭建（Python 3.13, MPS, PyTorch 2.7）
- [x] Gemini Local 自定义节点（Chat / ImageGen / ImageEdit / Veo）
- [x] Pony checkpoint 图生图 workflow
- [x] ReActor 换脸（纯换脸 + img2img 换脸 + FaceBoost）
- [x] 关闭 ReActor NSFW 过滤
- [x] txt2img + ReActor 换脸 workflow
- [x] IPAdapter Plus 安装 + 单人/双人 workflow
- [x] Wan Video 2.2 5B 下载配置
- [x] VideoHelperSuite / AnimateDiff / ComfyUI-Manager 安装
- [x] start.sh 加 --force-fp16 --enable-manager
- [x] Veo continuous video workflow + debug logging

## 当前已有模型

| 文件 | 类型 | 位置 |
|------|------|------|
| cyberrealisticPony_v160.safetensors | Checkpoint (Pony/SDXL) | models/checkpoints/ |
| wan2.1_i2v_720p_14B_fp16.safetensors | UNET (Wan 2.1 14B) | models/diffusion_models/ |
| wan2.2_ti2v_5B_fp16.safetensors | UNET (Wan 2.2 5B) | models/diffusion_models/ |
| umt5_xxl_fp8_e4m3fn_scaled.safetensors | Text Encoder (T5) | models/text_encoders/ |
| clip_vision_h.safetensors | CLIP Vision | models/clip_vision/ |
| wan_2.1_vae.safetensors | VAE (Wan 2.1) | models/vae/ |
| wan2.2_vae.safetensors | VAE (Wan 2.2) | models/vae/ |
| ip-adapter-plus-face_sdxl_vit-h.safetensors | IPAdapter Face | models/ipadapter/ |
| ip-adapter-plus_sdxl_vit-h.safetensors | IPAdapter Plus | models/ipadapter/ |
| inswapper_128.onnx | 换脸模型 | models/insightface/ |

## 当前 Workflows

| 文件 | 用途 |
|------|------|
| local_img2img+swap.json | Pony 图生图 + ReActor 换脸 |
| txt2img_faceswap.json | Pony 纯文生图 + ReActor 换脸 |
| local_face_swap_test.json | 纯换脸测试 |
| local_face_swap_boost.json | 换脸 + FaceBoost + RestoreFace |
| ipadapter_face.json | IPAdapter 单人参考脸生成 |
| ipadapter_2person.json | IPAdapter 双人 Regional 生成 |
| wan_img2vid.json | Wan 2.1 图生视频 |
| wan_txt2vid.json | Wan 2.1 纯文生视频 |
| wan2.2_tx2V.json | Wan 2.2 5B 文/图生视频 |
| flux_txt2img.json | Flux 文生图（已放弃，留存参考） |
| veo_continuous_video.json | Veo 连续视频生成 |
| itemchange.json | Gemini 多步换装 |

## 硬件笔记

- Mac M4 48GB：出图够用，视频生成 fp8/fp16 模型 MPS 不兼容（数值错误）
- Mac M4 Pro 64GB：内存多但 MPS 限制相同，GGUF Q4 量化是 Mac 跑视频的正确路线
- M4 Pro 48G/64G 和 M3 Max 36GB 同架构，GGUF 方案应该都能跑
- NVIDIA 4090：AI 生成质变（CUDA 比 MPS 快 10-20x），fp8 无兼容问题
- 本地视频重活交给 Veo 云端，Mac 做图片生成 + GGUF 视频小分辨率测试
