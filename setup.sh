#!/bin/bash

# Selene AI Assistant - Setup Script
# This script sets up all dependencies and downloads required models

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse command line arguments
USE_VENV=true
USE_USER_INSTALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --system)
            USE_VENV=false
            shift
            ;;
        --user)
            USE_VENV=false
            USE_USER_INSTALL=true
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Usage: $0 [--system] [--user]"
            echo "  (no flags)  : Install in virtual environment (default)"
            echo "  --system    : Install system-wide (requires sudo)"
            echo "  --user      : Install for current user only (~/.local)"
            exit 1
            ;;
    esac
done

if [ "$USE_VENV" = false ]; then
    if [ "$USE_USER_INSTALL" = true ]; then
        echo -e "${YELLOW}Installing for current user only (no virtual environment)${NC}\n"
    else
        echo -e "${YELLOW}Installing to system Python (no virtual environment)${NC}\n"
    fi
fi

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}🚀 Selene AI Assistant - Setup Script${NC}"
echo -e "${BLUE}============================================================${NC}\n"

# Check Python version
echo -e "${YELLOW}Checking Python version...${NC}"
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}[ERROR] Python 3 is not installed${NC}"
    
    # Detect package manager and suggest appropriate install command
    if command -v dnf &> /dev/null; then
        echo -e "${YELLOW}Install with: sudo dnf install python3${NC}"
    elif command -v apt &> /dev/null; then
        echo -e "${YELLOW}Install with: sudo apt install python3${NC}"
    fi
    exit 1
fi

PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')

if ! python3 -c "import sys; exit(0 if sys.version_info >= (3,8) else 1)"; then
    echo -e "${RED}[ERROR] Python 3.8 or higher is required. Found: $PYTHON_VERSION${NC}"
    exit 1
fi
echo -e "${GREEN}[OK] Python $PYTHON_VERSION detected${NC}\n"

# Detect OS type for better compatibility
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_TYPE=$ID
    echo -e "${BLUE}Detected OS: $NAME${NC}\n"
fi

# Check if Ollama is installed
echo -e "${YELLOW}Checking for Ollama...${NC}"
if ! command -v ollama &> /dev/null; then
    echo -e "${RED}[WARNING] Ollama is not installed${NC}"
    echo -e "${YELLOW}Install with:${NC}"
    echo -e "${BLUE}  curl -fsSL https://ollama.ai/install.sh | sh${NC}"
    echo -e "${YELLOW}After installation, run:${NC}"
    echo -e "${BLUE}  ollama pull gemma3:4b${NC}\n"
else
    echo -e "${GREEN}[OK] Ollama is installed${NC}\n"
fi

# Setup virtual environment or system installation
if [ "$USE_VENV" = true ]; then
    # Check if venv module is available
    echo -e "${YELLOW}Checking for venv module...${NC}"
    if ! python3 -c "import venv" 2>/dev/null; then
        echo -e "${RED}[ERROR] Python venv module not found${NC}"
        
        # Provide OS-specific installation instructions
        if command -v dnf &> /dev/null; then
            echo -e "${YELLOW}On Fedora/RHEL, install with:${NC}"
            echo -e "${BLUE}  sudo dnf install python3-virtualenv${NC}"
        elif command -v apt &> /dev/null; then
            echo -e "${YELLOW}On Ubuntu/Debian, install with:${NC}"
            echo -e "${BLUE}  sudo apt install python3-venv${NC}"
        fi
        
        echo -e "${YELLOW}Or run this script with --system flag to install system-wide:${NC}"
        echo -e "${BLUE}  ./setup.sh --system${NC}\n"
        exit 1
    fi
    echo -e "${GREEN}[OK] venv module available${NC}\n"

    # Create virtual environment
    echo -e "${YELLOW}Creating Python virtual environment...${NC}"
    if [ ! -d "venv" ]; then
        python3 -m venv venv
        echo -e "${GREEN}[OK] Virtual environment created${NC}\n"
    else
        echo -e "${GREEN}[OK] Virtual environment already exists${NC}\n"
    fi

    # Activate virtual environment
    echo -e "${YELLOW}Activating virtual environment...${NC}"
    source venv/bin/activate
    echo -e "${GREEN}[OK] Virtual environment activated${NC}\n"
else
    # System-wide or user installation
    if [ "$USE_USER_INSTALL" = true ]; then
        echo -e "${YELLOW}Installing packages for current user...${NC}"
        echo -e "${YELLOW}Note: Make sure ~/.local/bin is in your PATH${NC}\n"
    else
        echo -e "${YELLOW}Installing packages system-wide...${NC}"
        if [ "$EUID" -ne 0 ]; then
            echo -e "${YELLOW}Note: You may be prompted for sudo password${NC}\n"
        fi
    fi
fi

# Check for pip3
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}[ERROR] python3 is not available${NC}"
    exit 1
fi

# Upgrade pip
echo -e "${YELLOW}Upgrading pip...${NC}"
if [ "$USE_VENV" = true ]; then
    python3 -m pip install --upgrade pip > /dev/null 2>&1
elif [ "$USE_USER_INSTALL" = true ]; then
    python3 -m pip install --user --upgrade pip > /dev/null 2>&1
else
    if [ "$EUID" -ne 0 ]; then
        sudo -H python3 -m pip install --upgrade pip > /dev/null 2>&1
    else
        python3 -m pip install --upgrade pip > /dev/null 2>&1
    fi
fi
echo -e "${GREEN}[OK] pip upgraded${NC}\n"

# Install Python dependencies
echo -e "${YELLOW}Installing Python dependencies...${NC}"
if [ ! -f "requirements.txt" ]; then
    echo -e "${RED}[ERROR] requirements.txt not found${NC}"
    exit 1
fi

echo -e "${BLUE}This may take a few minutes...${NC}"

# Execute the appropriate install command based on installation type
# CRITICAL: Use python3 -m pip to avoid conflicts with GNU 'install' command on Fedora/RHEL
# Use --ignore-installed for system packages that conflict with RPM-installed versions
if [ "$USE_VENV" = true ]; then
    if python3 -m pip install -r requirements.txt; then
        echo -e "${GREEN}[OK] Dependencies installed${NC}\n"
    else
        echo -e "${RED}[ERROR] Failed to install dependencies${NC}"
        echo -e "${YELLOW}Try running manually:${NC}"
        echo -e "${BLUE}  python3 -m pip install -r requirements.txt${NC}\n"
        exit 1
    fi
elif [ "$USE_USER_INSTALL" = true ]; then
    if python3 -m pip install --user -r requirements.txt; then
        echo -e "${GREEN}[OK] Dependencies installed${NC}\n"
    else
        echo -e "${RED}[ERROR] Failed to install dependencies${NC}"
        echo -e "${YELLOW}Try running manually:${NC}"
        echo -e "${BLUE}  python3 -m pip install --user -r requirements.txt${NC}\n"
        exit 1
    fi
else
    # For system-wide install, use --ignore-installed to handle RPM-installed packages
    if [ "$EUID" -ne 0 ]; then
        if sudo -H python3 -m pip install --ignore-installed -r requirements.txt; then
            echo -e "${GREEN}[OK] Dependencies installed${NC}\n"
        else
            echo -e "${RED}[ERROR] Failed to install dependencies${NC}"
            echo -e "${YELLOW}Try running manually:${NC}"
            echo -e "${BLUE}  sudo -H python3 -m pip install --ignore-installed -r requirements.txt${NC}\n"
            exit 1
        fi
    else
        if python3 -m pip install --ignore-installed -r requirements.txt; then
            echo -e "${GREEN}[OK] Dependencies installed${NC}\n"
        else
            echo -e "${RED}[ERROR] Failed to install dependencies${NC}"
            echo -e "${YELLOW}Try running manually:${NC}"
            echo -e "${BLUE}  python3 -m pip install --ignore-installed -r requirements.txt${NC}\n"
            exit 1
        fi
    fi
fi

# Verify critical packages were installed
echo -e "${YELLOW}Verifying installation...${NC}"
VERIFY_FAILED=false

python3 -c "import flask" 2>/dev/null || { echo -e "${RED}  ✗ flask not installed${NC}"; VERIFY_FAILED=true; }
python3 -c "import flask_cors" 2>/dev/null || { echo -e "${RED}  ✗ flask-cors not installed${NC}"; VERIFY_FAILED=true; }
python3 -c "import ollama" 2>/dev/null || { echo -e "${RED}  ✗ ollama not installed${NC}"; VERIFY_FAILED=true; }
python3 -c "from piper import PiperVoice" 2>/dev/null || { echo -e "${RED}  ✗ piper-tts not installed${NC}"; VERIFY_FAILED=true; }

if [ "$VERIFY_FAILED" = true ]; then
    echo -e "\n${RED}[ERROR] Some packages failed to install${NC}"
    echo -e "${YELLOW}Try installing manually with:${NC}"
    if [ "$USE_USER_INSTALL" = true ]; then
        echo -e "${BLUE}  python3 -m pip install --user flask flask-cors ollama piper-tts pillow g2p-en numpy python-dotenv${NC}\n"
    else
        echo -e "${BLUE}  sudo -H python3 -m pip install --ignore-installed flask flask-cors ollama piper-tts pillow g2p-en numpy python-dotenv${NC}\n"
    fi
    exit 1
else
    echo -e "${GREEN}[OK] All packages verified${NC}\n"
fi

# Create necessary directories
echo -e "${YELLOW}Creating project directories...${NC}"
mkdir -p piper_models
mkdir -p images
mkdir -p temp
mkdir -p logs
mkdir -p modules
echo -e "${GREEN}[OK] Directories created${NC}\n"

# Make scripts executable
echo -e "${YELLOW}Setting script permissions...${NC}"
chmod +x setup.sh 2>/dev/null || true
chmod +x run.sh 2>/dev/null || true
chmod +x create_service.sh 2>/dev/null || true
chmod +x assistant.py 2>/dev/null || true
echo -e "${GREEN}[OK] Scripts are now executable${NC}\n"

# Download Piper TTS voice model
echo -e "${YELLOW}Downloading Piper TTS voice model...${NC}"
VOICE_MODEL="en_GB-jenny_dioco-medium"
MODEL_URL="https://github.com/rhasspy/piper/releases/download/v1.2.0/${VOICE_MODEL}.onnx"
CONFIG_URL="https://github.com/rhasspy/piper/releases/download/v1.2.0/${VOICE_MODEL}.onnx.json"

if [ ! -f "piper_models/${VOICE_MODEL}.onnx" ]; then
    echo -e "${BLUE}  Downloading ${VOICE_MODEL}.onnx (~100MB)...${NC}"
    if command -v curl &> /dev/null; then
        curl -L -o "piper_models/${VOICE_MODEL}.onnx" "$MODEL_URL"
    elif command -v wget &> /dev/null; then
        wget -O "piper_models/${VOICE_MODEL}.onnx" "$MODEL_URL"
    else
        echo -e "${RED}[ERROR] Neither curl nor wget is available${NC}"
        echo -e "${YELLOW}Install with: sudo apt install curl${NC}"
        exit 1
    fi
    echo -e "${GREEN}  [OK] Model file downloaded${NC}"
else
    echo -e "${GREEN}  [OK] Model file already exists${NC}"
fi

if [ ! -f "piper_models/${VOICE_MODEL}.onnx.json" ]; then
    echo -e "${BLUE}  Downloading ${VOICE_MODEL}.onnx.json...${NC}"
    if command -v curl &> /dev/null; then
        curl -L -o "piper_models/${VOICE_MODEL}.onnx.json" "$CONFIG_URL"
    elif command -v wget &> /dev/null; then
        wget -O "piper_models/${VOICE_MODEL}.onnx.json" "$CONFIG_URL"
    fi
    echo -e "${GREEN}  [OK] Config file downloaded${NC}"
else
    echo -e "${GREEN}  [OK] Config file already exists${NC}"
fi
echo ""

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}Creating .env configuration file...${NC}"
    cat > .env << 'EOF'
# Selene AI Assistant Configuration

# Server Configuration
FLASK_HOST=0.0.0.0
FLASK_PORT=5000
FLASK_DEBUG=false

# Ollama Configuration
OLLAMA_MODEL=gemma3:4b
OLLAMA_BASE_URL=http://localhost:11434

# Assistant Configuration
ASSISTANT_NAME=Selene
ASSISTANT_BIRTHDAY=2025-10-15

# Piper TTS Configuration
PIPER_MODEL_NAME=en_GB-jenny_dioco-medium
PIPER_MODELS_DIR=piper_models

# Paths
IMAGES_DIR=images
TEMP_DIR=temp

# Logging
LOG_LEVEL=INFO
LOG_FILE=logs/selene.log

# Feature Flags
ENABLE_TTS=true
ENABLE_VOICE_RECOGNITION=true
ENABLE_LIP_SYNC=true

# Performance
MAX_CONVERSATION_HISTORY=10
TTS_CACHE_SIZE=100
EOF
    echo -e "${GREEN}[OK] .env file created${NC}\n"
else
    echo -e "${GREEN}[OK] .env file already exists${NC}\n"
fi

# Download NLTK data (required for g2p-en)
echo -e "${YELLOW}Downloading NLTK data for phoneme conversion...${NC}"
python3 << 'PYTHON_SCRIPT'
import nltk
import sys

try:
    # Download required NLTK data
    nltk.download('averaged_perceptron_tagger_eng', quiet=True)
    nltk.download('cmudict', quiet=True)
    print("NLTK data downloaded successfully")
except Exception as e:
    print(f"Error downloading NLTK data: {e}", file=sys.stderr)
    sys.exit(1)
PYTHON_SCRIPT

if [ $? -eq 0 ]; then
    echo -e "${GREEN}[OK] NLTK data downloaded${NC}\n"
else
    echo -e "${RED}[WARNING] Failed to download NLTK data${NC}\n"
fi

# Final instructions
echo -e "${BLUE}============================================================${NC}"
echo -e "${GREEN}✅ Setup Complete!${NC}"
echo -e "${BLUE}============================================================${NC}\n"

echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Make sure Ollama is running: ${BLUE}ollama serve${NC}"
echo -e "2. Pull a model (if not already): ${BLUE}ollama pull gemma3:4b${NC}"
echo -e "3. Place character images in the ${BLUE}images/${NC} directory"
echo -e "4. Start the assistant with: ${BLUE}./run.sh${NC}"
echo -e "   ${YELLOW}(or use the commands below for manual start)${NC}\n"

if [ "$USE_VENV" = true ]; then
    echo -e "${YELLOW}Manual start commands (with venv):${NC}"
    echo -e "  ${BLUE}source venv/bin/activate${NC}"
    echo -e "  ${BLUE}python assistant.py${NC}\n"
elif [ "$USE_USER_INSTALL" = true ]; then
    echo -e "${YELLOW}Manual start commands (user install):${NC}"
    echo -e "  ${BLUE}export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}"
    echo -e "  ${BLUE}python3 assistant.py${NC}\n"
else
    echo -e "${YELLOW}Manual start command (system install):${NC}"
    echo -e "  ${BLUE}python3 assistant.py${NC}\n"
fi

echo -e "${YELLOW}Required character images:${NC}"
echo -e "  - character_open.png (eyes open)"
echo -e "  - character_half.png (eyes half-closed)"
echo -e "  - character_closed.png (eyes closed)"
echo -e "  - mouth_closed_neutral.png"
echo -e "  - mouth_closed_smile.png"
echo -e "  - mouth_small_open.png"
echo -e "  - mouth_round_o.png"
echo -e "  - mouth_round_o2.png"
echo -e "  - mouth_small_oval.png"
echo -e "  - mouth_wide_open.png"
echo -e "  - mouth_wide_smile.png"
echo -e "  - mouth_very_wide.png\n"

if [ "$USE_VENV" = false ]; then
    echo -e "${YELLOW}Note: Installed system-wide. To uninstall:${NC}"
    if [ "$USE_USER_INSTALL" = true ]; then
        echo -e "${BLUE}  python3 -m pip uninstall flask flask-cors ollama piper-tts pillow g2p-en numpy python-dotenv${NC}\n"
    else
        echo -e "${BLUE}  sudo -H python3 -m pip uninstall flask flask-cors ollama piper-tts pillow g2p-en numpy python-dotenv${NC}\n"
    fi
    
    echo -e "${YELLOW}Optional: Run as a systemd service${NC}"
    echo -e "To create a systemd service file, run:"
    echo -e "${BLUE}  sudo ./create_service.sh${NC}"
    echo -e "(This will create /etc/systemd/system/selene.service)\n"
fi

echo -e "${GREEN}Happy chatting with Selene! 🤖${NC}\n"
