#!/bin/bash

# Selene AI Assistant - run.sh
# This single script handles everything: installation, configuration, and running

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Configuration
INSTALL_TYPE=""
INSTALL_NGINX=false
INSTALL_SERVICE=false
DOMAIN_NAME="selene.local"
SKIP_SETUP=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --system)
            INSTALL_TYPE="system"
            shift
            ;;
        --user)
            INSTALL_TYPE="user"
            shift
            ;;
        --venv)
            INSTALL_TYPE="venv"
            shift
            ;;
        --skip-setup)
            SKIP_SETUP=true
            shift
            ;;
        --with-nginx)
            INSTALL_NGINX=true
            shift
            ;;
        --with-service)
            INSTALL_SERVICE=true
            shift
            ;;
        --domain)
            DOMAIN_NAME="$2"
            shift 2
            ;;
        --help|-h)
            echo -e "${CYAN}Selene AI Assistant - run.sh${NC}"
            echo -e "${CYAN}══════════════════════════════════════════════════${NC}\n"
            echo -e "${GREEN}Usage:${NC} ./run.sh [options]\n"
            echo -e "${BLUE}Installation Options:${NC}"
            echo -e "  --venv           Install in virtual environment (default)"
            echo -e "  --system         Install system-wide (requires sudo)"
            echo -e "  --user           Install for current user only\n"
            echo -e "${BLUE}Feature Options:${NC}"
            echo -e "  --with-nginx     Also setup nginx reverse proxy"
            echo -e "  --with-service   Also setup systemd service"
            echo -e "  --domain NAME    Domain name for nginx (default: selene.local)\n"
            echo -e "${BLUE}Other Options:${NC}"
            echo -e "  --skip-setup     Skip installation if already done"
            echo -e "  --help, -h       Show this help message\n"
            echo -e "${YELLOW}Examples:${NC}"
            echo -e "  ./run.sh                                  # Simple install and run"
            echo -e "  ./run.sh --system --with-nginx            # System install with nginx"
            echo -e "  ./run.sh --skip-setup                     # Just run (if already installed)"
            echo -e "  ./run.sh --with-nginx --domain chat.local # Custom domain\n"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo -e "${YELLOW}Use --help for usage information${NC}"
            exit 1
            ;;
    esac
done

# Set default installation type if not specified
if [ -z "$INSTALL_TYPE" ]; then
    INSTALL_TYPE="venv"
fi

# Banner
clear
echo -e "${BLUE}"
cat << "EOF"
╔══════════════════════════════════════════════════════════╗
║                                                            ║
║   ███████╗███████╗██╗     ███████╗███╗   ██╗███████╗      ║
║   ██╔════╝██╔════╝██║     ██╔════╝████╗  ██║██╔════╝      ║
║   ███████╗█████╗  ██║     █████╗  ██╔██╗ ██║█████╗        ║
║   ╚════██║██╔══╝  ██║     ██╔══╝  ██║╚██╗██║██╔══╝        ║
║   ███████║███████╗███████╗███████╗██║ ╚████║███████╗      ║
║   ╚══════╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═══╝╚══════╝      ║
║                                                            ║
║          Fedora Linux AI Assistant                        ║
║          One-Command Setup & Run                          ║
║                                                            ║
╚══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}\n"

#############################################################################
# INSTALLATION FUNCTIONS
#############################################################################

check_python() {
    echo -e "${YELLOW}Checking Python version...${NC}"
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}[ERROR] Python 3 is not installed${NC}"
        if command -v pacman &> /dev/null; then
            echo -e "${YELLOW}Install with: sudo pacman -S python${NC}"
        elif command -v dnf &> /dev/null; then
            echo -e "${YELLOW}Install with: sudo dnf install python3${NC}"
        elif command -v apt &> /dev/null; then
            echo -e "${YELLOW}Install with: sudo apt install python3${NC}"
        fi
        exit 1
    fi

    if ! python3 -c "import sys; exit(0 if sys.version_info >= (3,8) else 1)"; then
        echo -e "${RED}[ERROR] Python 3.8 or higher is required${NC}"
        exit 1
    fi
    
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
    PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)
    
    echo -e "${GREEN}[OK] Python $PYTHON_VERSION detected${NC}\n"
    
    # Check for Python 3.14+ - known compatibility issues
    if [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -ge 14 ]; then
        echo -e "${RED}╔══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║  WARNING: Python 3.14+ Detected                           ║${NC}"
        echo -e "${RED}╚══════════════════════════════════════════════════════════╝${NC}\n"
        echo -e "${YELLOW}Python 3.14 is very new and many packages lack compatible wheels,${NC}"
        echo -e "${YELLOW}especially onnxruntime and piper-tts which are CRITICAL for TTS.${NC}\n"
        
        if command -v pacman &> /dev/null; then
            echo -e "${BLUE}Checking for alternative Python versions...${NC}\n"
            
            # Check what Python versions are available
            AVAILABLE_PYTHONS=()
            for ver in 3.11 3.12 3.13; do
                if command -v python$ver &> /dev/null; then
                    AVAILABLE_PYTHONS+=("python$ver")
                fi
            done
            
            if [ ${#AVAILABLE_PYTHONS[@]} -gt 0 ]; then
                echo -e "${GREEN}Found compatible Python versions:${NC}"
                for py in "${AVAILABLE_PYTHONS[@]}"; do
                    VER=$($py --version 2>&1)
                    echo -e "  ${GREEN}✓${NC} $py ($VER)"
                done
                echo
                echo -e "${YELLOW}RECOMMENDED: Use one of these instead${NC}"
                echo -e "${BLUE}Example:${NC}"
                echo -e "  ${py} -m venv venv"
                echo -e "  source venv/bin/activate"
                echo -e "  ./run.sh --skip-setup\n"
            else
                echo -e "${YELLOW}No compatible Python versions found. Installing Python 3.12...${NC}\n"
                
                read -p "$(echo -e ${GREEN}'Install Python 3.12 now? (y/n) [y]: '${NC})" -n 1 -r INSTALL_PY
                echo
                INSTALL_PY=${INSTALL_PY:-y}
                
                if [[ $INSTALL_PY =~ ^[Yy]$ ]]; then
                    if command -v yay &> /dev/null; then
                        yay -S python312 --noconfirm
                    elif command -v paru &> /dev/null; then
                        paru -S python312 --noconfirm
                    else
                        sudo pacman -S python312 --noconfirm
                    fi
                    
                    if command -v python3.12 &> /dev/null; then
                        echo -e "${GREEN}[OK] Python 3.12 installed!${NC}\n"
                        echo -e "${YELLOW}Now run these commands:${NC}"
                        echo -e "  ${BLUE}rm -rf venv${NC}"
                        echo -e "  ${BLUE}python3.12 -m venv venv${NC}"
                        echo -e "  ${BLUE}source venv/bin/activate${NC}"
                        echo -e "  ${BLUE}./run.sh --skip-setup${NC}\n"
                        exit 0
                    else
                        echo -e "${RED}[ERROR] Failed to install Python 3.12${NC}"
                        exit 1
                    fi
                else
                    echo -e "${RED}Cannot proceed with Python 3.14${NC}"
                    echo -e "${YELLOW}Install a compatible version and try again${NC}"
                    exit 1
                fi
            fi
            
            echo -e "${RED}Cannot proceed with Python 3.14 for TTS installation${NC}"
            exit 1
        else
            echo -e "${YELLOW}Consider using Python 3.11-3.13 for better compatibility${NC}\n"
            read -p "$(echo -e ${YELLOW}'Continue anyway? (not recommended) (y/n) [n]: '${NC})" -n 1 -r CONTINUE
            echo
            CONTINUE=${CONTINUE:-n}
            
            if [[ ! $CONTINUE =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    fi
}

check_ollama() {
    echo -e "${YELLOW}Checking for Ollama...${NC}"
    if ! command -v ollama &> /dev/null; then
        echo -e "${RED}[WARNING] Ollama is not installed${NC}"
        echo -e "${YELLOW}Install with:${NC}"
        echo -e "${BLUE}  curl -fsSL https://ollama.ai/install.sh | sh${NC}"
        echo -e "${YELLOW}After installation, run:${NC}"
        echo -e "${BLUE}  ollama serve${NC}"
        echo -e "${BLUE}  ollama pull gemma3:4b${NC}\n"
        return 1
    else
        echo -e "${GREEN}[OK] Ollama is installed${NC}"
        
        # Check if Ollama service is running
        if ! curl -s http://localhost:11434/api/version > /dev/null 2>&1; then
            echo -e "${YELLOW}[WARNING] Ollama service is not running${NC}"
            echo -e "${YELLOW}Start it with: ${BLUE}ollama serve${NC}\n"
        else
            # Check if gemma3:4b model is installed
            echo -e "${YELLOW}Checking for gemma3:4b model...${NC}"
            if ollama list 2>/dev/null | grep -q "gemma3:4b"; then
                echo -e "${GREEN}[OK] gemma3:4b model is installed${NC}\n"
            else
                echo -e "${RED}[WARNING] gemma3:4b model is not installed${NC}"
                echo -e "${YELLOW}This model is required for Selene to function.${NC}\n"
                
                read -p "$(echo -e ${GREEN}'Would you like to download it now? (y/n) [y]: '${NC})" -n 1 -r INSTALL_MODEL
                echo
                INSTALL_MODEL=${INSTALL_MODEL:-y}
                
                if [[ $INSTALL_MODEL =~ ^[Yy]$ ]]; then
                    echo -e "${BLUE}Downloading gemma3:4b (this may take several minutes)...${NC}\n"
                    if ollama pull gemma3:4b; then
                        echo -e "${GREEN}[OK] gemma3:4b model installed successfully${NC}\n"
                    else
                        echo -e "${RED}[ERROR] Failed to download gemma3:4b${NC}"
                        echo -e "${YELLOW}You can install it manually later with: ${BLUE}ollama pull gemma3:4b${NC}\n"
                        return 1
                    fi
                else
                    echo -e "${YELLOW}Skipping model download.${NC}"
                    echo -e "${YELLOW}Install it manually with: ${BLUE}ollama pull gemma3:4b${NC}\n"
                    return 1
                fi
            fi
        fi
        return 0
    fi
}

setup_venv() {
    echo -e "${YELLOW}Setting up virtual environment...${NC}"
    
    if ! python3 -c "import venv" 2>/dev/null; then
        echo -e "${RED}[ERROR] Python venv module not found${NC}"
        if command -v pacman &> /dev/null; then
            echo -e "${YELLOW}The venv module should be included with Python on Arch${NC}"
            echo -e "${YELLOW}Try reinstalling: sudo pacman -S python${NC}"
        elif command -v dnf &> /dev/null; then
            echo -e "${YELLOW}Install with: sudo dnf install python3-virtualenv${NC}"
        elif command -v apt &> /dev/null; then
            echo -e "${YELLOW}Install with: sudo apt install python3-venv${NC}"
        fi
        exit 1
    fi
    
    if [ ! -d "venv" ]; then
        python3 -m venv venv
        echo -e "${GREEN}[OK] Virtual environment created${NC}"
    else
        echo -e "${GREEN}[OK] Virtual environment already exists${NC}"
    fi
    
    source venv/bin/activate
    echo -e "${GREEN}[OK] Virtual environment activated${NC}\n"
}

install_dependencies() {
    echo -e "${YELLOW}Installing Python dependencies...${NC}"
    echo -e "${BLUE}This may take a few minutes...${NC}\n"
    
    # For Arch-based systems, try to install system packages first
    if command -v pacman &> /dev/null; then
        echo -e "${CYAN}Detected Arch-based system - checking for system packages...${NC}\n"
        
        # Check if we have an AUR helper
        AUR_HELPER=""
        if command -v yay &> /dev/null; then
            AUR_HELPER="yay"
        elif command -v paru &> /dev/null; then
            AUR_HELPER="paru"
        fi
        
        if [ -z "$AUR_HELPER" ]; then
            echo -e "${RED}[ERROR] No AUR helper (yay/paru) detected!${NC}"
            echo -e "${RED}TTS requires onnxruntime from AUR${NC}\n"
            echo -e "${YELLOW}Install an AUR helper first:${NC}"
            echo -e "${BLUE}  sudo pacman -S yay${NC}"
            echo -e "${BLUE}  (or) sudo pacman -S paru${NC}\n"
            echo -e "${RED}Cannot proceed without AUR helper for TTS support${NC}"
            exit 1
        fi
        
        echo -e "${YELLOW}Installing onnxruntime from AUR (required for piper-tts)...${NC}"
        echo -e "${BLUE}This is a large package and may take several minutes...${NC}\n"
        
        # Try to install without prompting (use defaults)
        if ! $AUR_HELPER -S --noconfirm python-onnxruntime-cpu 2>&1 | grep -v "warning:"; then
            echo -e "${RED}[ERROR] Failed to install onnxruntime from AUR${NC}"
            echo -e "${RED}TTS functionality requires this package${NC}\n"
            echo -e "${YELLOW}Try installing manually:${NC}"
            echo -e "${BLUE}  $AUR_HELPER -S python-onnxruntime-cpu${NC}\n"
            exit 1
        fi
        echo -e "${GREEN}[OK] onnxruntime installed from AUR${NC}\n"
        
        # CRITICAL: For venv installs, we need to link the system onnxruntime into the venv
        # because pip's onnxruntime doesn't have Python 3.14 wheels yet
        if [ "$INSTALL_TYPE" = "venv" ]; then
            echo -e "${YELLOW}Linking system onnxruntime to virtual environment...${NC}"
            
            # Find the system onnxruntime installation
            SYSTEM_ONNX=$(python3 -c "import sys; print([p for p in sys.path if 'site-packages' in p and 'local' not in p][0])" 2>/dev/null)
            VENV_SITE=$(python3 -c "import sys; print([p for p in sys.path if 'site-packages' in p and 'venv' in p][0])" 2>/dev/null)
            
            if [ -d "$SYSTEM_ONNX/onnxruntime" ] && [ -d "$VENV_SITE" ]; then
                # Create symlink to system onnxruntime in venv
                ln -sf "$SYSTEM_ONNX/onnxruntime" "$VENV_SITE/onnxruntime" 2>/dev/null || true
                ln -sf "$SYSTEM_ONNX"/onnxruntime*.dist-info "$VENV_SITE/" 2>/dev/null || true
                echo -e "${GREEN}[OK] System onnxruntime linked to venv${NC}\n"
            else
                echo -e "${YELLOW}[WARNING] Could not link system onnxruntime${NC}\n"
            fi
        fi
    fi
    
    # Upgrade pip first
    python3 -m pip install --upgrade pip > /dev/null 2>&1
    
    # Install core packages first (these are stable)
    echo -e "${BLUE}Installing core packages...${NC}"
    case $INSTALL_TYPE in
        venv)
            if ! python3 -m pip install flask flask-cors ollama pillow numpy python-dotenv; then
                echo -e "${RED}[ERROR] Failed to install core packages${NC}"
                exit 1
            fi
            ;;
        user)
            if ! python3 -m pip install --user flask flask-cors ollama pillow numpy python-dotenv; then
                echo -e "${RED}[ERROR] Failed to install core packages${NC}"
                exit 1
            fi
            ;;
        system)
            if [ "$EUID" -ne 0 ]; then
                if ! sudo -H python3 -m pip install --ignore-installed flask flask-cors ollama pillow numpy python-dotenv; then
                    echo -e "${RED}[ERROR] Failed to install core packages${NC}"
                    exit 1
                fi
            else
                if ! python3 -m pip install --ignore-installed flask flask-cors ollama pillow numpy python-dotenv; then
                    echo -e "${RED}[ERROR] Failed to install core packages${NC}"
                    exit 1
                fi
            fi
            ;;
    esac
    echo -e "${GREEN}[OK] Core packages installed${NC}\n"
    
    # Install TTS packages - CRITICAL for this project
    echo -e "${BLUE}Installing TTS and phoneme packages (REQUIRED)...${NC}"
    echo -e "${YELLOW}Note: This may take a few minutes${NC}\n"
    
    TTS_INSTALL_FAILED=false
    
    case $INSTALL_TYPE in
        venv)
            # Install g2p-en first (simpler)
            if ! python3 -m pip install g2p-en 2>&1; then
                echo -e "${RED}[ERROR] Failed to install g2p-en${NC}"
                TTS_INSTALL_FAILED=true
            fi
            
            # Try piper-tts - install piper-phonemize first to help resolve dependencies
            echo -e "${BLUE}Installing piper-phonemize...${NC}"
            python3 -m pip install piper-phonemize 2>&1 | grep -v "WARNING:" || echo -e "${YELLOW}piper-phonemize may need to be built${NC}"
            
            echo -e "${BLUE}Installing piper-tts (this may take a moment)...${NC}"
            if ! python3 -m pip install piper-tts --no-deps 2>&1; then
                echo -e "${RED}[ERROR] Failed to install piper-tts${NC}"
                TTS_INSTALL_FAILED=true
            fi
            ;;
        user)
            if ! python3 -m pip install --user g2p-en 2>&1; then
                echo -e "${RED}[ERROR] Failed to install g2p-en${NC}"
                TTS_INSTALL_FAILED=true
            fi
            
            python3 -m pip install --user piper-phonemize 2>&1 | grep -v "WARNING:" || echo -e "${YELLOW}piper-phonemize may need to be built${NC}"
            
            if ! python3 -m pip install --user piper-tts --no-deps 2>&1; then
                echo -e "${RED}[ERROR] Failed to install piper-tts${NC}"
                TTS_INSTALL_FAILED=true
            fi
            ;;
        system)
            if [ "$EUID" -ne 0 ]; then
                if ! sudo -H python3 -m pip install --ignore-installed g2p-en 2>&1; then
                    echo -e "${RED}[ERROR] Failed to install g2p-en${NC}"
                    TTS_INSTALL_FAILED=true
                fi
                
                sudo -H python3 -m pip install --ignore-installed piper-phonemize 2>&1 | grep -v "WARNING:" || echo -e "${YELLOW}piper-phonemize may need to be built${NC}"
                
                if ! sudo -H python3 -m pip install --ignore-installed piper-tts --no-deps 2>&1; then
                    echo -e "${RED}[ERROR] Failed to install piper-tts${NC}"
                    TTS_INSTALL_FAILED=true
                fi
            else
                if ! python3 -m pip install --ignore-installed g2p-en 2>&1; then
                    echo -e "${RED}[ERROR] Failed to install g2p-en${NC}"
                    TTS_INSTALL_FAILED=true
                fi
                
                python3 -m pip install --ignore-installed piper-phonemize 2>&1 | grep -v "WARNING:" || echo -e "${YELLOW}piper-phonemize may need to be built${NC}"
                
                if ! python3 -m pip install --ignore-installed piper-tts --no-deps 2>&1; then
                    echo -e "${RED}[ERROR] Failed to install piper-tts${NC}"
                    TTS_INSTALL_FAILED=true
                fi
            fi
            ;;
    esac
    
    if [ "$TTS_INSTALL_FAILED" = true ]; then
        echo
        echo -e "${RED}╔══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║  CRITICAL ERROR: TTS Installation Failed                  ║${NC}"
        echo -e "${RED}╚══════════════════════════════════════════════════════════╝${NC}\n"
        echo -e "${YELLOW}This project requires TTS and phoneme support.${NC}"
        echo -e "${YELLOW}Installation cannot continue without these components.${NC}\n"
        exit 1
    fi
    
    echo -e "${GREEN}[OK] TTS packages installed${NC}\n"
    
    # Verify ALL critical components
    echo -e "${YELLOW}Verifying installation...${NC}\n"
    
    VERIFICATION_FAILED=false
    MISSING_COMPONENTS=()
    
    # Check core packages
    if ! python3 -c "import flask" 2>/dev/null; then
        MISSING_COMPONENTS+=("flask")
        VERIFICATION_FAILED=true
    fi
    
    if ! python3 -c "import flask_cors" 2>/dev/null; then
        MISSING_COMPONENTS+=("flask-cors")
        VERIFICATION_FAILED=true
    fi
    
    if ! python3 -c "import ollama" 2>/dev/null; then
        MISSING_COMPONENTS+=("ollama")
        VERIFICATION_FAILED=true
    fi
    
    # Check TTS - CRITICAL
    if ! python3 -c "from piper import PiperVoice" 2>/dev/null; then
        MISSING_COMPONENTS+=("piper-tts")
        VERIFICATION_FAILED=true
    fi
    
    # Check phoneme support - CRITICAL
    if ! python3 -c "from g2p_en import G2p" 2>/dev/null; then
        MISSING_COMPONENTS+=("g2p-en (phoneme support)")
        VERIFICATION_FAILED=true
    fi
    
    # Check onnxruntime - CRITICAL for TTS
    if ! python3 -c "import onnxruntime" 2>/dev/null; then
        MISSING_COMPONENTS+=("onnxruntime")
        VERIFICATION_FAILED=true
    fi
    
    if [ "$VERIFICATION_FAILED" = true ]; then
        echo -e "${RED}╔══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║  VERIFICATION FAILED: Missing Critical Components         ║${NC}"
        echo -e "${RED}╚══════════════════════════════════════════════════════════╝${NC}\n"
        echo -e "${RED}Missing components:${NC}"
        for component in "${MISSING_COMPONENTS[@]}"; do
            echo -e "  ${RED}✗${NC} $component"
        done
        echo
        echo -e "${YELLOW}This project requires ALL components for TTS functionality.${NC}"
        echo -e "${YELLOW}Please fix the installation issues above and try again.${NC}\n"
        
        if command -v pacman &> /dev/null; then
            echo -e "${BLUE}For Arch-based systems with Python 3.14:${NC}"
            echo -e "${BLUE}  The issue is likely Python 3.14 compatibility.${NC}"
            echo -e "${BLUE}  Recommended: Use Python 3.11-3.13 instead:${NC}"
            echo -e "${BLUE}    1. sudo pacman -S python311${NC}"
            echo -e "${BLUE}    2. python3.11 -m venv venv${NC}"
            echo -e "${BLUE}    3. source venv/bin/activate${NC}"
            echo -e "${BLUE}    4. Re-run this script with --skip-setup${NC}\n"
        fi
        
        exit 1
    fi
    
    # Success!
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✓ ALL Components Verified Successfully!                  ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}\n"
    echo -e "${GREEN}✓ Flask & Web Framework${NC}"
    echo -e "${GREEN}✓ Ollama AI Integration${NC}"
    echo -e "${GREEN}✓ Piper TTS (Neural Voice)${NC}"
    echo -e "${GREEN}✓ G2P Phoneme Processing${NC}"
    echo -e "${GREEN}✓ ONNX Runtime${NC}"
    echo -e "${GREEN}✓ All dependencies ready!${NC}\n"
}

create_directories() {
    echo -e "${YELLOW}Creating project directories...${NC}"
    mkdir -p piper_models images temp logs modules
    echo -e "${GREEN}[OK] Directories created${NC}\n"
}

download_voice_model() {
    echo -e "${YELLOW}Downloading Piper TTS voice model...${NC}"
    
    VOICE_MODEL="en_GB-jenny_dioco-medium"
    MODEL_URL="https://github.com/rhasspy/piper/releases/download/v1.2.0/${VOICE_MODEL}.onnx"
    CONFIG_URL="https://github.com/rhasspy/piper/releases/download/v1.2.0/${VOICE_MODEL}.onnx.json"
    
    if [ ! -f "piper_models/${VOICE_MODEL}.onnx" ]; then
        echo -e "${BLUE}  Downloading ${VOICE_MODEL}.onnx (~100MB)...${NC}"
        if command -v curl &> /dev/null; then
            curl -L -o "piper_models/${VOICE_MODEL}.onnx" "$MODEL_URL" 2>&1 | grep -v "^  "
        elif command -v wget &> /dev/null; then
            wget -q --show-progress -O "piper_models/${VOICE_MODEL}.onnx" "$MODEL_URL"
        else
            echo -e "${RED}[ERROR] Neither curl nor wget is available${NC}"
            exit 1
        fi
        echo -e "${GREEN}  [OK] Model downloaded${NC}"
    else
        echo -e "${GREEN}  [OK] Model already exists${NC}"
    fi
    
    if [ ! -f "piper_models/${VOICE_MODEL}.onnx.json" ]; then
        echo -e "${BLUE}  Downloading config...${NC}"
        if command -v curl &> /dev/null; then
            curl -L -s -o "piper_models/${VOICE_MODEL}.onnx.json" "$CONFIG_URL"
        elif command -v wget &> /dev/null; then
            wget -q -O "piper_models/${VOICE_MODEL}.onnx.json" "$CONFIG_URL"
        fi
        echo -e "${GREEN}  [OK] Config downloaded${NC}"
    else
        echo -e "${GREEN}  [OK] Config already exists${NC}"
    fi
    echo
}

create_env_file() {
    if [ -f ".env" ]; then
        echo -e "${GREEN}[OK] .env file already exists${NC}\n"
        return
    fi
    
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
}

download_nltk_data() {
    echo -e "${YELLOW}Downloading NLTK data...${NC}"
    python3 << 'PYTHON_SCRIPT'
import nltk
try:
    nltk.download('averaged_perceptron_tagger_eng', quiet=True)
    nltk.download('cmudict', quiet=True)
except:
    pass
PYTHON_SCRIPT
    echo -e "${GREEN}[OK] NLTK data downloaded${NC}\n"
}

setup_nginx() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${YELLOW}Nginx setup requires sudo privileges...${NC}"
        SUDO_CMD="sudo"
    else
        SUDO_CMD=""
    fi
    
    echo -e "${CYAN}═════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Setting Up Nginx Reverse Proxy${NC}"
    echo -e "${CYAN}═════════════════════════════════════════════${NC}\n"
    
    # Install nginx if needed
    if ! command -v nginx &> /dev/null; then
        echo -e "${YELLOW}Installing nginx...${NC}"
        if command -v pacman &> /dev/null; then
            $SUDO_CMD pacman -S --noconfirm nginx
        elif command -v dnf &> /dev/null; then
            $SUDO_CMD dnf install -y nginx
        elif command -v apt &> /dev/null; then
            $SUDO_CMD apt update && $SUDO_CMD apt install -y nginx
        else
            echo -e "${RED}[ERROR] Unsupported package manager. Please install nginx manually.${NC}"
            return 1
        fi
    fi
    
    # Detect OS for config path
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_ID=$ID
    fi
    
    # Create nginx config
    if [[ "$OS_ID" == "fedora" ]] || [[ "$OS_ID" == "rhel" ]]; then
        NGINX_CONF="/etc/nginx/conf.d/selene.conf"
    else
        NGINX_CONF="/etc/nginx/sites-available/selene"
        $SUDO_CMD mkdir -p /etc/nginx/sites-enabled
    fi
    
    $SUDO_CMD tee "$NGINX_CONF" > /dev/null << EOF
server {
    listen 80;
    server_name $DOMAIN_NAME;
    client_max_body_size 16M;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_connect_timeout 600s;
        proxy_send_timeout 600s;
        proxy_read_timeout 600s;
    }

    access_log /var/log/nginx/selene_access.log;
    error_log /var/log/nginx/selene_error.log;
}
EOF
    
    # Enable site on Ubuntu/Debian
    if [[ "$OS_ID" == "ubuntu" ]] || [[ "$OS_ID" == "debian" ]]; then
        $SUDO_CMD ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/selene
    fi
    
    # Configure SELinux on Fedora/RHEL
    if [[ "$OS_ID" == "fedora" ]] || [[ "$OS_ID" == "rhel" ]]; then
        if command -v semanage &> /dev/null; then
            $SUDO_CMD semanage port -a -t http_port_t -p tcp 5000 2>/dev/null || \
            $SUDO_CMD semanage port -m -t http_port_t -p tcp 5000
            $SUDO_CMD setsebool -P httpd_can_network_connect 1
        fi
    fi
    
    # Test and restart nginx
    if $SUDO_CMD nginx -t 2>&1 | grep -q "successful"; then
        $SUDO_CMD systemctl enable nginx
        $SUDO_CMD systemctl restart nginx
        echo -e "${GREEN}[OK] Nginx configured and running${NC}\n"
    else
        echo -e "${RED}[ERROR] Nginx configuration failed${NC}\n"
        return 1
    fi
    
    # Update /etc/hosts
    if ! grep -q "$DOMAIN_NAME" /etc/hosts; then
        echo "127.0.0.1    $DOMAIN_NAME" | $SUDO_CMD tee -a /etc/hosts > /dev/null
        echo -e "${GREEN}[OK] Added $DOMAIN_NAME to /etc/hosts${NC}\n"
    fi
}

setup_service() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${YELLOW}Service setup requires sudo privileges...${NC}"
        SUDO_CMD="sudo"
    else
        SUDO_CMD=""
    fi
    
    echo -e "${CYAN}═════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Setting Up Systemd Service${NC}"
    echo -e "${CYAN}═════════════════════════════════════════════${NC}\n"
    
    INSTALL_DIR=$(pwd)
    INSTALL_USER=${SUDO_USER:-$USER}
    SERVICE_FILE="/etc/systemd/system/selene.service"
    
    $SUDO_CMD tee "$SERVICE_FILE" > /dev/null << EOF
[Unit]
Description=Selene AI Assistant
After=network.target ollama.service
Wants=ollama.service

[Service]
Type=simple
User=$INSTALL_USER
WorkingDirectory=$INSTALL_DIR
Environment="PATH=/usr/local/bin:/usr/bin:/bin"
Environment="PYTHONUNBUFFERED=1"
ExecStart=/usr/bin/python3 $INSTALL_DIR/assistant.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
    
    $SUDO_CMD chmod 644 "$SERVICE_FILE"
    $SUDO_CMD systemctl daemon-reload
    $SUDO_CMD systemctl enable selene
    $SUDO_CMD systemctl start selene
    
    sleep 2
    if $SUDO_CMD systemctl is-active --quiet selene; then
        echo -e "${GREEN}[OK] Service created and running${NC}\n"
    else
        echo -e "${YELLOW}[WARNING] Service created but not running${NC}"
        echo -e "${YELLOW}Check logs: sudo journalctl -u selene -n 20${NC}\n"
    fi
}

#############################################################################
# MAIN INSTALLATION FLOW
#############################################################################

if [ "$SKIP_SETUP" = false ]; then
    echo -e "${CYAN}🤖 Starting Selene Installation${NC}\n"
    
    # Show installation plan
    echo -e "${CYAN}═════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Installation Configuration${NC}"
    echo -e "${CYAN}═════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Install Type:${NC}      ${GREEN}$INSTALL_TYPE${NC}"
    echo -e "${BLUE}  Nginx Proxy:${NC}       ${GREEN}$([ "$INSTALL_NGINX" = true ] && echo "Yes ($DOMAIN_NAME)" || echo "No")${NC}"
    echo -e "${BLUE}  Systemd Service:${NC}  ${GREEN}$([ "$INSTALL_SERVICE" = true ] && echo "Yes" || echo "No")${NC}"
    echo -e "${CYAN}═════════════════════════════════════════════${NC}\n"
    
    sleep 1
    
    # Run installation steps
    check_python
    check_ollama
    
    if [ "$INSTALL_TYPE" = "venv" ]; then
        setup_venv
    fi
    
    install_dependencies
    create_directories
    download_voice_model
    create_env_file
    download_nltk_data
    
    # Optional components
    if [ "$INSTALL_NGINX" = true ]; then
        setup_nginx
    fi
    
    if [ "$INSTALL_SERVICE" = true ]; then
        setup_service
    fi
    
    # Installation complete
    echo -e "${GREEN}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════╗
║              ✅  Installation Complete!  ✅                ║
╚══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}\n"
    
    sleep 1
else
    echo -e "${YELLOW}Skipping installation (--skip-setup flag used)${NC}\n"
fi

#############################################################################
# RUN THE APPLICATION
#############################################################################

# If service was installed, don't run directly
if [ "$INSTALL_SERVICE" = true ] && [ "$SKIP_SETUP" = false ]; then
    echo -e "${GREEN}✅ Selene is running as a systemd service${NC}\n"
    
    if [ "$INSTALL_NGINX" = true ]; then
        echo -e "${CYAN}📱 Access Selene at: ${GREEN}http://$DOMAIN_NAME${NC}\n"
    else
        echo -e "${CYAN}📱 Access Selene at: ${GREEN}http://localhost:5000${NC}\n"
    fi
    
    echo -e "${YELLOW}Service Commands:${NC}"
    echo -e "  ${BLUE}sudo systemctl status selene${NC}   - Check status"
    echo -e "  ${BLUE}sudo systemctl stop selene${NC}     - Stop service"
    echo -e "  ${BLUE}sudo journalctl -u selene -f${NC}   - View logs\n"
    
    exit 0
fi

# Otherwise, run the application directly
echo -e "${CYAN}═════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Starting Selene AI Assistant${NC}"
echo -e "${CYAN}═════════════════════════════════════════════${NC}\n"

# Check if Ollama is running
if ! curl -s http://localhost:11434/api/version > /dev/null 2>&1; then
    echo -e "${RED}[WARNING] Ollama doesn't appear to be running${NC}"
    echo -e "${YELLOW}Start it in another terminal with: ${BLUE}ollama serve${NC}\n"
    read -p "Press Enter to continue anyway, or Ctrl+C to exit..."
fi

# Determine Python command
if [ "$INSTALL_TYPE" = "venv" ] && [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
    PYTHON_CMD="python"
else
    PYTHON_CMD="python3"
fi

# Check if assistant.py exists
if [ ! -f "assistant.py" ]; then
    echo -e "${RED}[ERROR] assistant.py not found in current directory${NC}"
    echo -e "${YELLOW}Make sure you're in the correct directory${NC}"
    exit 1
fi

# Show access information
echo -e "${GREEN}🚀 Starting Selene...${NC}\n"

if [ "$INSTALL_NGINX" = true ]; then
    echo -e "${CYAN}📱 Access Selene at: ${GREEN}http://$DOMAIN_NAME${NC}"
else
    echo -e "${CYAN}📱 Access Selene at: ${GREEN}http://localhost:5000${NC}"
fi

echo -e "${CYAN}🛑 Press Ctrl+C to stop${NC}\n"
echo -e "${CYAN}═════════════════════════════════════════════${NC}\n"

# Run the application
exec $PYTHON_CMD assistant.py