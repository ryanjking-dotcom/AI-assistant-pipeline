#!/bin/bash

# Selene AI Assistant - Run Script
# Universal launcher that works with venv or system installation

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Starting Selene AI Assistant...${NC}\n"

# Check if venv exists AND the activation script is present
if [ -f "venv/bin/activate" ]; then
    echo -e "${YELLOW}Detected virtual environment, activating...${NC}"
    source venv/bin/activate
    echo -e "${GREEN}[OK] Virtual environment activated${NC}\n"
    PYTHON_CMD="python"
elif [ -d "venv" ]; then
    # venv directory exists but activation script is missing
    echo -e "${YELLOW}[WARNING] venv directory exists but appears incomplete${NC}"
    echo -e "${YELLOW}Using system Python instead...${NC}\n"
    PYTHON_CMD="python3"
else
    echo -e "${YELLOW}No virtual environment detected, using system Python...${NC}\n"
    PYTHON_CMD="python3"
fi

# Check if Python is available
if ! command -v $PYTHON_CMD &> /dev/null; then
    echo -e "${RED}[ERROR] $PYTHON_CMD is not available${NC}"
    if [ "$PYTHON_CMD" = "python" ]; then
        echo -e "${YELLOW}Trying python3 instead...${NC}\n"
        PYTHON_CMD="python3"
        if ! command -v $PYTHON_CMD &> /dev/null; then
            echo -e "${RED}[ERROR] Neither python nor python3 is available${NC}"
            exit 1
        fi
    else
        exit 1
    fi
fi

# Check if dependencies are installed
echo -e "${YELLOW}Checking Python dependencies...${NC}"
MISSING_DEPS=()

$PYTHON_CMD -c "import flask" 2>/dev/null || MISSING_DEPS+=("flask")
$PYTHON_CMD -c "import flask_cors" 2>/dev/null || MISSING_DEPS+=("flask-cors")
$PYTHON_CMD -c "import ollama" 2>/dev/null || MISSING_DEPS+=("ollama")
$PYTHON_CMD -c "from piper import PiperVoice" 2>/dev/null || MISSING_DEPS+=("piper-tts")

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo -e "${RED}[ERROR] Missing required Python packages: ${MISSING_DEPS[*]}${NC}\n"
    echo -e "${YELLOW}Please run the setup script first:${NC}"
    echo -e "${BLUE}  ./setup.sh --system${NC}  (for system-wide installation)"
    echo -e "${BLUE}  ./setup.sh --user${NC}    (for user-only installation)"
    echo -e "${BLUE}  ./setup.sh${NC}           (for virtual environment)\n"
    exit 1
fi
echo -e "${GREEN}[OK] All dependencies installed${NC}\n"

# Check if Ollama is running
echo -e "${YELLOW}Checking Ollama...${NC}"
if ! curl -s http://localhost:11434/api/version > /dev/null 2>&1; then
    echo -e "${RED}[WARNING] Ollama doesn't appear to be running${NC}"
    echo -e "${YELLOW}Start it with: ${BLUE}ollama serve${NC}\n"
else
    echo -e "${GREEN}[OK] Ollama is running${NC}\n"
fi

# Run the assistant
exec $PYTHON_CMD assistant.py
