# Workflow 模型下载清单

每个 workflow 需要哪些模型文件，按用途分组。

---

## 一、换脸 Workflows

需要模型：
| 文件 | 目录 | 来源 |
|------|------|------|
| `cyberrealisticPony_v160.safetensors` | `models/checkpoints/` | CivitAI 搜 "cyberrealisticPony" |
| `inswapper_128.onnx` | `models/insightface/` | HuggingFace 搜 "inswapper_128" |

| Workflow | 说明 |
|----------|------|
| `local_img2img+swap.json` | Pony 图生图 + ReActor 换脸 |
| `txt2img_faceswap.json` | Pony 文生图 + ReActor 换脸 |
| `local_face_swap_test.json` | 纯换脸测试 |
| `local_face_swap_boost.json` | 换脸 + FaceBoost + RestoreFace |
| `video_faceswap.json` | 视频逐帧换脸 |

---

## 二、IPAdapter Workflows

需要模型：
| 文件 | 目录 | 来源 |
|------|------|------|
| `cyberrealisticPony_v160.safetensors` | `models/checkpoints/` | CivitAI |
| `clip_vision_h.safetensors` | `models/clip_vision/` | HuggingFace: `laion/CLIP-ViT-H-14-laion2B-s32B-b79K` |
| `ip-adapter-plus-face_sdxl_vit-h.safetensors` | `models/ipadapter/` | HuggingFace: `h94/IP-Adapter` |

| Workflow | 说明 |
|----------|------|
| `ipadapter_face.json` | IPAdapter 单人参考脸生成 |
| `ipadapter_2person.json` | IPAdapter 双人 Regional 生成 |

---

## 三、Wan 2.2 GGUF i2v（Mac 推荐）

需要模型：
| 文件 | 目录 | 来源 |
|------|------|------|
| `wan2.2_i2v_high_noise_14B_Q4_K_S.gguf` | `models/diffusion_models/` | `huggingface.co/bullerwins/Wan2.2-I2V-A14B-GGUF` |
| `wan2.2_i2v_low_noise_14B_Q4_K_S.gguf` | `models/diffusion_models/` | 同上 |
| `wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors` | `models/loras/` | `huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/tree/main/split_files/loras` |
| `wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors` | `models/loras/` | 同上 |
| `umt5_xxl_fp8_e4m3fn_scaled.safetensors` | `models/text_encoders/` | `huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/tree/main/split_files/text_encoders` |
| `wan_2.1_vae.safetensors` | `models/vae/` | `huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/tree/main/split_files/vae` |

| Workflow | 说明 |
|----------|------|
| `wan2_2_14B_i2v_Macbook_tech-practice.json` | GGUF Q4 双模型两阶段 + 4步LoRA（Mac 验证可行） |

---

## 四、Wan 旧版（fp16/fp8，Mac 上有问题）

需要模型：
| 文件 | 目录 | 备注 |
|------|------|------|
| `wan2.2_ti2v_5B_fp16.safetensors` | `models/diffusion_models/` | Mac MPS 花屏 |
| `wan2.1_i2v_720p_14B_fp16.safetensors` | `models/diffusion_models/` | Mac OOM |
| `wan2.2_vae.safetensors` | `models/vae/` | |
| `umt5_xxl_fp8_e4m3fn_scaled.safetensors` | `models/text_encoders/` | |
| `clip_vision_h.safetensors` | `models/clip_vision/` | wan_img2vid 用 |

| Workflow | 说明 |
|----------|------|
| `wan2.2_i2v.json` | Wan 2.2 5B i2v（Mac 花屏，不推荐） |
| `wan2.2_tx2V.json` | Wan 2.2 5B t2v（Mac 花屏，不推荐） |
| `wan_img2vid.json` | Wan 2.1 14B i2v（Mac OOM，不推荐） |
| `wan_txt2vid.json` | Wan 2.1 14B t2v（Mac OOM，不推荐） |

---

## 五、Gemini API Workflows（无需本地模型）

依赖 `gemini_local.py` 自定义节点 + 本地 Gemini API bridge (`localhost:11211`)。

| Workflow | 说明 |
|----------|------|
| `veo_continuous_video.json` | Veo 连续视频生成 |
| `itemchange.json` / `itemchange2.json` | Gemini 多步换装 |
| `cartoon gen.json` / `cartoon gen 2.json` | Gemini 卡通生成 |
| `cartoon video.json` / `cartoon video 2.json` | Gemini 卡通视频 |
| `Dylan.json` | Gemini 生成 |
| `photoMerge.json` | Gemini 照片合成 |
| `slack cat workflow.json` | Gemini slack cat |
| `themeChat.json` | Gemini 主题聊天 |

---

## 六、Flux（已放弃）

| 文件 | 目录 | 备注 |
|------|------|------|
| `flux1-dev.safetensors` | `models/checkpoints/` | Mac 上太慢，不推荐 |
| `ae.safetensors` | `models/vae/` | Flux VAE |

| Workflow | 说明 |
|----------|------|
| `flux_txt2img.json` | Flux 文生图（已放弃） |

---

## 模型下载优先级

### 必下（核心功能）
1. `cyberrealisticPony_v160.safetensors` — 换脸/IPAdapter 基础
2. `inswapper_128.onnx` — ReActor 换脸核心
3. `clip_vision_h.safetensors` — IPAdapter 必需
4. `ip-adapter-plus-face_sdxl_vit-h.safetensors` — IPAdapter 必需

### 必下（GGUF 视频生成）
5. `wan2.2_i2v_high_noise_14B_Q4_K_S.gguf` — ~8GB
6. `wan2.2_i2v_low_noise_14B_Q4_K_S.gguf` — ~8GB
7. `wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors` — ~400MB
8. `wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors` — ~400MB
9. `umt5_xxl_fp8_e4m3fn_scaled.safetensors` — ~6.3GB
10. `wan_2.1_vae.safetensors` — ~242MB

### 可跳过
- Wan fp16/fp8 模型（Mac 不能用）
- Flux 模型（已放弃）
