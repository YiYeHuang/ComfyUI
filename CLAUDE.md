# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ComfyUI is a graph/node-based visual AI engine for designing and executing diffusion model pipelines. Python backend (3.10+), aiohttp WebSocket/REST server, separately compiled TypeScript/Vue frontend in `/web/`.

## Common Commands

```bash
# Run the server (default: http://127.0.0.1:8188)
python main.py

# Useful flags
python main.py --listen 0.0.0.0 --port 8188
python main.py --cpu                    # CPU-only mode
python main.py --force-fp16             # Force half precision
python main.py --enable-manager         # Enable ComfyUI-Manager extension

# Lint
ruff check .

# Tests
pip install -r tests-unit/requirements.txt
pytest tests-unit/                              # All unit tests
pytest tests-unit/comfy_test/some_test.py       # Single file
pytest tests-unit/ -m "not inference"           # Skip inference tests
```

## Architecture

### Entry Points
- **`main.py`** — App startup: env setup, CLI args, custom node loading, DB migrations, server launch
- **`server.py`** — `PromptServer` class: aiohttp server with WebSocket (`/ws`) and REST endpoints, queue management, security middleware stack (CORS, CSP, origin validation)
- **`execution.py`** — Workflow execution engine: node dependency resolution, execution ordering, caching strategies (Basic, LRU, RAMPressure, Hierarchical)

### Core Modules
| Path | Role |
|------|------|
| `comfy/` | Core diffusion: samplers, model management, CLIP, model detection, device handling |
| `comfy/cli_args.py` | All CLI argument definitions |
| `comfy_execution/` | Execution engine internals: graph representation, caching, jobs, progress, validation |
| `comfy_api/` | Public API definitions with versioning |
| `comfy_api_nodes/` | Built-in API nodes for external services (Gemini, OpenAI, BFL, Kling, etc.) |
| `comfy_extras/` | ~100 extended node modules (samplers, audio, video, compositing, GLSL, logic, etc.) |
| `nodes.py` | Core node implementations (large file, ~102KB) |
| `folder_paths.py` | Model directory paths and supported file type mappings |
| `app/` | App layer: user management, model files, frontend management, custom node manager |
| `api_server/` | API route handlers and services |

### Node System
Nodes are the fundamental building blocks. Every node is a Python class registered in `NODE_CLASS_MAPPINGS`:

```python
class MyNode(ComfyNodeABC):
    @classmethod
    def INPUT_TYPES(cls) -> InputTypeDict:
        return {"required": {...}, "optional": {...}}

    RETURN_TYPES = (IO.IMAGE,)
    FUNCTION = "execute"
    CATEGORY = "my_category"

    def execute(self, ...):
        return (result,)
```

**Node sources loaded in order:**
1. Core nodes (`nodes.py`)
2. Extra nodes (`comfy_extras/`)
3. API nodes (`comfy_api_nodes/`)
4. Custom nodes (`custom_nodes/` directory, dynamically imported)

### Execution Flow
1. Client connects via WebSocket, negotiates feature flags
2. Client queues a workflow prompt (JSON graph of connected nodes)
3. Server validates inputs, resolves node dependencies, determines execution order
4. Nodes execute with caching; progress/status sent back via WebSocket
5. Results saved to `output/` directory

### Model Paths
Models organized under `models/` with 25+ subdirectories: `checkpoints/`, `vae/`, `loras/`, `text_encoders/`, `diffusion_models/`, `controlnet/`, `upscale_models/`, `embeddings/`, etc. Additional paths configurable via `extra_model_paths.yaml`.

### Database
SQLAlchemy + Alembic migrations in `alembic_db/` for user preferences and workflow history.

## Linting Config
Ruff rules: E, W, F, N805, S307, S102, T (print usage). Ignored: E501 (line length), E722, E731, E712, E402, E741. Config in `pyproject.toml`.

## Test Structure
- `tests-unit/` — Unit tests (primary)
- `tests/` — Integration/execution tests
- Markers: `inference`, `execution`
- Framework: pytest with pytest-asyncio
