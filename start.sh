#!/bin/bash
# ComfyUI Startup Script

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Activate virtual environment
if [ ! -d ".venv" ]; then
    echo "Error: .venv not found. Run ./setup.sh first."
    exit 1
fi

source .venv/bin/activate

# Default settings
HOST="127.0.0.1"
PORT="8188"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --lan)
            HOST="0.0.0.0"
            shift
            ;;
        --port)
            PORT="$2"
            shift 2
            ;;
        --cpu)
            EXTRA_ARGS="$EXTRA_ARGS --cpu"
            shift
            ;;
        *)
            EXTRA_ARGS="$EXTRA_ARGS $1"
            shift
            ;;
    esac
done

echo "=== Starting ComfyUI ==="
echo "URL: http://${HOST}:${PORT}"
echo "Press Ctrl+C to stop"
echo ""

python main.py --listen "$HOST" --port "$PORT" --force-fp16 --enable-manager $EXTRA_ARGS
