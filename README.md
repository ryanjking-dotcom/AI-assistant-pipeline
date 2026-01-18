# Selene AI Assistant

<div align="center">

```
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║   ███████╗███████╗██╗     ███████╗███╗   ██╗███████╗    ║
║   ██╔════╝██╔════╝██║     ██╔════╝████╗  ██║██╔════╝    ║
║   ███████╗█████╗  ██║     █████╗  ██╔██╗ ██║█████╗      ║
║   ╚════██║██╔══╝  ██║     ██╔══╝  ██║╚██╗██║██╔══╝      ║
║   ███████║███████╗███████╗███████╗██║ ╚████║███████╗    ║
║   ╚══════╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═══╝╚══════╝    ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
```

**An elegant AI assistant for Fedora Linux with Piper Neural TTS and Phoneme-Based Lip Sync**

[Features](#-features) • [Quick Start](#-quick-start) • [Installation](#-installation) • [Usage](#-usage) • [Configuration](#%EF%B8%8F-configuration)

</div>

---

## 🌟 Features

- **🤖 Powered by Ollama** - Local AI inference using Gemma 3:4b model
- **🎙️ Neural Text-to-Speech** - High-quality voice synthesis using Piper TTS
- **💋 Phoneme-Based Lip Sync** - Realistic animated mouth movements synchronized to speech
- **🎤 Voice Input** - Hands-free interaction with speech recognition (Chrome/Edge/Safari)
- **🎨 Elegant Visual Character** - Animated character with blinking and natural expressions
- **🔒 Privacy-Focused** - Runs entirely on your machine, no data sent to external servers
- **⚡ One-Command Setup** - Automated installation script for quick deployment
- **🐧 Linux-First Design** - Optimized for Fedora Linux with full systemd integration

---

## 📋 Prerequisites

Before installing Selene, ensure you have:

### Required
- **Linux** (Fedora, Arch, Ubuntu, Debian, or similar)
- **Python 3.8+** (Python 3.11-3.13 recommended, avoid 3.14+)
- **Ollama** installed and running
- **AUR helper** (yay or paru) if on Arch-based systems - required for TTS

### Recommended
- 8GB+ RAM for smooth AI model operation
- Modern web browser (Chrome, Edge, or Safari for voice input)

---

## 🚀 Quick Start

The fastest way to get Selene running:

```bash
# 1. Clone the repository
git clone <repository-url>
cd selene-assistant

# 2. Make the setup script executable
chmod +x run.sh

# 3. Run the one-command installer
./run.sh
```

The script will:
- ✅ Check Python version compatibility
- ✅ Verify Ollama installation and download the Gemma 3:4b model
- ✅ Set up a Python virtual environment
- ✅ Install all dependencies (including TTS)
- ✅ Download the Piper TTS voice model
- ✅ Create necessary directories
- ✅ Start the web server

**Access Selene at:** `http://localhost:5000`

---

## 📦 Installation

### Option 1: Virtual Environment (Recommended)

```bash
./run.sh --venv
```

This creates an isolated Python environment for Selene.

### Option 2: System-Wide Installation

```bash
./run.sh --system
```

Requires sudo privileges. Installs packages system-wide.

### Option 3: User Installation

```bash
./run.sh --user
```

Installs packages in your user directory without sudo.

### Advanced Installation Options

#### With Nginx Reverse Proxy
```bash
./run.sh --with-nginx --domain selene.local
```

#### As a Systemd Service
```bash
./run.sh --with-service
```

#### Skip Setup (if already installed)
```bash
./run.sh --skip-setup
```

---

## 🔧 Manual Installation

If you prefer manual installation:

### Understanding Virtual Environments

A virtual environment keeps Selene's Python packages isolated from your system Python. This prevents conflicts and makes it easy to manage dependencies.

**Creating a virtual environment:**
```bash
python3 -m venv venv
```

**Activating the virtual environment:**

The activation command depends on your shell:

| Shell | Command |
|-------|---------|
| bash/zsh | `source venv/bin/activate` |
| fish | `source venv/bin/activate.fish` |
| csh/tcsh | `source venv/bin/activate.csh` |
| PowerShell (Windows) | `venv\Scripts\Activate.ps1` |

**You'll know it's activated** when you see `(venv)` at the start of your prompt:
```bash
(venv) user@hostname:~/selene-assistant$
```

**Deactivating:**
```bash
deactivate
```

**Important:** Always activate the virtual environment before running Selene or installing packages!

---

### 1. Install Ollama

```bash
# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Start Ollama service
ollama serve

# Download the Gemma 3:4b model
ollama pull gemma3:4b
```

### 2. Install Python Dependencies

#### For Arch-based systems:
```bash
# Install AUR helper if not already installed
sudo pacman -S yay

# Install onnxruntime from AUR (required for TTS)
yay -S python-onnxruntime-cpu

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
# For bash/zsh:
source venv/bin/activate
# For fish shell:
source venv/bin/activate.fish
# For csh/tcsh:
source venv/bin/activate.csh

# Install Python packages
pip install -r requirements.txt
```

#### For Fedora:
```bash
# Install venv module if not already installed
sudo dnf install python3-virtualenv

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
# For bash/zsh:
source venv/bin/activate
# For fish shell:
source venv/bin/activate.fish
# For csh/tcsh:
source venv/bin/activate.csh

# Install Python packages
pip install -r requirements.txt
```

#### For Ubuntu/Debian:
```bash
# Install venv module if not already installed
sudo apt install python3-venv

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
# For bash/zsh:
source venv/bin/activate
# For fish shell:
source venv/bin/activate.fish
# For csh/tcsh:
source venv/bin/activate.csh

# Install Python packages
pip install -r requirements.txt
```

### 3. Download Piper TTS Voice Model

```bash
mkdir -p piper_models
cd piper_models

# Download Jenny Dioco (British English) voice
wget https://github.com/rhasspy/piper/releases/download/v1.2.0/en_GB-jenny_dioco-medium.onnx
wget https://github.com/rhasspy/piper/releases/download/v1.2.0/en_GB-jenny_dioco-medium.onnx.json

cd ..
```

### 4. Create Configuration File

```bash
cp .env.example .env
# Edit .env to customize settings
```

### 5. Run Selene

```bash
# Make sure virtual environment is activated first!
# For bash/zsh:
source venv/bin/activate
# For fish shell:
source venv/bin/activate.fish
# For csh/tcsh:
source venv/bin/activate.csh

# Then run Selene
python assistant.py
```

---

## 💬 Usage

### Starting Selene

```bash
# Simple start (uses virtual environment if available)
./run.sh

# Or manually with virtual environment
# For bash/zsh:
source venv/bin/activate
# For fish shell:
source venv/bin/activate.fish
# For csh/tcsh:
source venv/bin/activate.csh

# Then start
python assistant.py
```

### Using the Web Interface

1. Open your browser to `http://localhost:5000`
2. **Enable audio** when prompted (required for TTS)
3. Type a message or click **"Voice Input"** for hands-free interaction
4. Watch Selene respond with animated expressions and voice

### Voice Input

- Click **"Voice Input"** button
- Speak naturally
- Recording automatically stops after 3.5 seconds of silence
- Click **"Stop"** to manually end recording

### Example Interactions

```
You: "Hello Selene, how are you today?"
Selene: "Hello! I'm doing wonderfully, thank you for asking..."

You: "What's your favorite thing about Fedora Linux?"
Selene: "I appreciate Fedora's commitment to pushing forward..."

You: "Can you tell me about your birthday?"
Selene: "I was born on October 15, 2025. That makes me..."
```

---

## ⚙️ Configuration

### Configuration File (.env)

All settings are in `.env`:

```bash
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

# Performance
MAX_CONVERSATION_HISTORY=10
TTS_CACHE_SIZE=100
```

### Changing the AI Model

Edit `.env` and change `OLLAMA_MODEL`:

```bash
OLLAMA_MODEL=llama3.2  # or any Ollama model
```

Then download the model:

```bash
ollama pull llama3.2
```

### Changing the Voice

Download a different Piper voice from the [Piper releases page](https://github.com/rhasspy/piper/releases/tag/v1.2.0) and update `.env`:

```bash
PIPER_MODEL_NAME=en_US-lessac-medium  # American English
```

---

## 🐛 Troubleshooting

### Python 3.14+ Issues

**Problem:** TTS installation fails on Python 3.14+

**Solution:** Use Python 3.11-3.13:

```bash
# For Arch-based systems
sudo pacman -S python312
python3.12 -m venv venv
source venv/bin/activate
./run.sh --skip-setup
```

### Ollama Connection Error

**Problem:** "Ollama doesn't appear to be running"

**Solution:**

```bash
# Start Ollama service
ollama serve

# Or enable as systemd service
sudo systemctl enable --now ollama
```

### Voice Input Not Working

**Problem:** "Speech recognition is not supported"

**Solution:** Use Chrome, Edge, or Safari - Firefox doesn't support Web Speech API

### TTS Installation Failed

**Problem:** "CRITICAL ERROR: TTS Installation Failed"

**Solution for Arch users:**

```bash
# Install AUR helper first
sudo pacman -S yay

# Then re-run
./run.sh
```

### Port Already in Use

**Problem:** Port 5000 is already taken

**Solution:** Change the port in `.env`:

```bash
FLASK_PORT=5001
```

---

## 📁 Project Structure

```
selene-assistant/
├── run.sh                 # One-command setup script
├── assistant.py           # Main entry point
├── requirements.txt       # Python dependencies
├── .env                   # Configuration file
├── modules/
│   ├── __init__.py       # Module initialization
│   ├── api.py            # Flask routes and web interface
│   ├── tts.py            # Piper TTS integration
│   ├── phonemes.py       # Phoneme-based lip sync
│   └── utils.py          # Configuration and utilities
├── piper_models/         # TTS voice models
├── images/               # Character images
├── temp/                 # Temporary files
└── logs/                 # Application logs
```

---

## 🎨 Character Images

Selene's visual appearance consists of layered images:

### Eye States
- `character_open.png` - Normal open eyes
- `character_half.png` - Half-closed eyes
- `character_closed.png` - Closed eyes (blinking)

### Mouth States
- `mouth_closed_neutral.png` - Resting position
- `mouth_small_open.png` - Small opening
- `mouth_wide_open.png` - Wide opening
- `mouth_round_o.png` - O shape
- And more...

Place custom images in the `images/` directory to customize her appearance.

---

## 🔒 Security & Privacy

- **100% Local** - All processing happens on your machine
- **No External APIs** - No data sent to third parties
- **Open Source** - Fully auditable code
- **Creator Privacy** - Selene never discloses creator information

---

## 🛠️ Development

### Running in Debug Mode

```bash
# Edit .env
FLASK_DEBUG=true

# Run
python assistant.py
```

### Viewing Logs

```bash
# Real-time logs
tail -f logs/selene.log

# If running as service
sudo journalctl -u selene -f
```

### Stopping the Service

```bash
# If running directly
Ctrl+C

# If running as service
sudo systemctl stop selene
```

---

## 📝 System Requirements

### Minimum
- 4GB RAM
- 2 CPU cores
- 5GB disk space (models + dependencies)
- Linux kernel 4.4+

### Recommended
- 8GB+ RAM
- 4+ CPU cores
- 10GB disk space
- Modern GPU (optional, for faster inference)

---

## 🤝 Contributing

Contributions are welcome! Areas for improvement:

- Additional voice models
- More character animations
- Enhanced lip sync accuracy
- Performance optimizations
- Documentation improvements

---

## 📄 License

This project is open source. See the LICENSE file for details.

---

## 🙏 Acknowledgments

- **Piper TTS** - High-quality neural text-to-speech
- **Ollama** - Local LLM inference
- **g2p-en** - Grapheme-to-phoneme conversion
- **Fedora Project** - Inspiration and community

---

## 📞 Support

If you encounter issues:

1. Check the [Troubleshooting](#-troubleshooting) section
2. View logs: `tail -f logs/selene.log`
3. Ensure all dependencies are installed
4. Try the automated setup: `./run.sh`

---

<div align="center">

**Made with 💙 for the Fedora Linux community**

*Bringing clarity and elegance to AI assistance*

</div>
