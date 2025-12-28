# Selene AI Assistant

<div align="center">

```
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║   ███████╗███████╗██╗     ███████╗███╗   ██╗███████╗      ║
║   ██╔════╝██╔════╝██║     ██╔════╝████╗  ██║██╔════╝      ║
║   ███████╗█████╗  ██║     █████╗  ██╔██╗ ██║█████╗        ║
║   ╚════██║██╔══╝  ██║     ██╔══╝  ██║╚██╗██║██╔══╝        ║
║   ███████║███████╗███████╗███████╗██║ ╚████║███████╗      ║
║   ╚══════╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═══╝╚══════╝      ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
```

**A Fedora Linux AI Assistant with Neural TTS and Phoneme-Based Lip Sync**

</div>

## 🌟 Features

- 🤖 **AI-Powered Conversations** - Uses Ollama for local AI models
- 🎙️ **Neural Text-to-Speech** - High-quality voice synthesis with Piper TTS
- 💬 **Phoneme-Based Lip Sync** - Realistic mouth animations synchronized with speech
- 🖼️ **Visual Character** - Animated character with dynamic expressions
- 🌐 **Web Interface** - Clean, accessible web UI
- 🔒 **Privacy-First** - Everything runs locally on your machine
- ⚙️ **Easy Deployment** - Systemd service and nginx reverse proxy support

## 📋 Prerequisites

### System Requirements
- **OS**: Fedora, RHEL, Ubuntu, Debian, or compatible Linux distribution
- **Python**: 3.8 or higher
- **RAM**: 4GB minimum (8GB+ recommended for larger AI models)
- **Disk**: 5GB free space for models and dependencies

### Required Software
- **Python 3.8+** with pip
- **Ollama** - For running AI models locally

## 🚀 Quick Start (Recommended)

The easiest way to get started is using the master installer:

```bash
# Clone or download the project
cd ai-assistant-env

# Make the installer executable
chmod +x install.sh

# Run the interactive installer
./install.sh
```

The installer will guide you through:
1. ✅ Installing all Python dependencies
2. 🌐 Optional nginx reverse proxy setup
3. 🔧 Optional systemd service configuration

That's it! The installer handles everything automatically.

## 🛠️ Manual Installation

If you prefer more control, follow these steps:

### Step 1: Install Ollama

```bash
# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Start Ollama
ollama serve

# Pull an AI model (in a new terminal)
ollama pull gemma3:4b
```

### Step 2: Install Selene

Choose your preferred installation method:

#### Option A: Virtual Environment (Recommended for Development)
```bash
./setup.sh
```

#### Option B: System-Wide Installation
```bash
./setup.sh --system
```

#### Option C: User-Only Installation
```bash
./setup.sh --user
```

The setup script will:
- Install all Python dependencies
- Download the Piper TTS voice model (~100MB)
- Create necessary directories
- Generate a `.env` configuration file

### Step 3: Add Character Images

Place your character images in the `images/` directory:

**Required images:**
- `character_open.png` - Eyes open
- `character_half.png` - Eyes half-closed
- `character_closed.png` - Eyes closed
- `mouth_closed_neutral.png`
- `mouth_closed_smile.png`
- `mouth_small_open.png`
- `mouth_round_o.png`
- `mouth_round_o2.png`
- `mouth_small_oval.png`
- `mouth_wide_open.png`
- `mouth_wide_smile.png`
- `mouth_very_wide.png`

### Step 4: Start Selene

```bash
./run.sh
```

Access Selene at: **http://localhost:5000**

## 🌐 Setting Up Nginx (Optional)

For a cleaner URL without port numbers:

```bash
sudo ./setup_nginx.sh
```

This allows you to access Selene at: **http://selene.local**

### Network Access

To access Selene from other devices on your network:

1. Find your server's IP address:
   ```bash
   ip addr show | grep inet
   ```

2. On other devices, add to `/etc/hosts`:
   ```
   192.168.1.100    selene.local
   ```

## 🔧 Running as a System Service

To run Selene automatically on boot:

```bash
# Create the systemd service
sudo ./create_service.sh

# Enable and start
sudo systemctl enable selene
sudo systemctl start selene

# Check status
sudo systemctl status selene
```

### Service Management

Use the convenient control script:

```bash
# Start the service
./selene-control.sh start

# Stop the service
./selene-control.sh stop

# Restart the service
./selene-control.sh restart

# Check status
./selene-control.sh status

# View live logs
./selene-control.sh logs

# Enable auto-start on boot
./selene-control.sh enable
```

## ⚙️ Configuration

Edit the `.env` file to customize Selene:

```env
# Server Configuration
FLASK_HOST=0.0.0.0
FLASK_PORT=5000

# AI Model (change to any Ollama model)
OLLAMA_MODEL=gemma3:4b
OLLAMA_BASE_URL=http://localhost:11434

# Assistant Identity
ASSISTANT_NAME=Selene
ASSISTANT_BIRTHDAY=2025-10-15

# Voice Model
PIPER_MODEL_NAME=en_GB-jenny_dioco-medium

# Features
ENABLE_TTS=true
ENABLE_VOICE_RECOGNITION=true
ENABLE_LIP_SYNC=true

# Performance
MAX_CONVERSATION_HISTORY=10
```

After changing the configuration, restart Selene:
```bash
./selene-control.sh restart
```

## 🔍 Troubleshooting

### Selene Won't Start

Run the diagnostic tool:
```bash
./diagnose.sh
```

This checks:
- Is Selene running?
- Is nginx configured correctly?
- Is Ollama running?
- Are ports available?
- Recent error logs

### Common Issues

**"Ollama connection failed"**
```bash
# Start Ollama
ollama serve
```

**"Model not found"**
```bash
# Pull the model
ollama pull gemma3:4b
```

**"Port 5000 already in use"**
```bash
# Find what's using the port
sudo lsof -i :5000

# Or change the port in .env
FLASK_PORT=5001
```

**"Piper TTS not available"**
```bash
# Reinstall dependencies
./setup.sh --system
```

### View Logs

```bash
# Application logs
tail -f logs/selene.log

# Service logs (if using systemd)
sudo journalctl -u selene -f

# Nginx logs (if using nginx)
sudo tail -f /var/log/nginx/selene_error.log
```

## 📁 Project Structure

```
ai-assistant-env/
├── assistant.py              # Main application
├── .env                      # Configuration file
├── requirements.txt          # Python dependencies
│
├── modules/                  # Python modules
│   ├── utils.py             # Configuration & utilities
│   ├── phonemes.py          # Phoneme processing
│   ├── tts.py               # Text-to-speech
│   └── api.py               # Flask routes
│
├── images/                   # Character images
├── piper_models/            # TTS voice models
├── logs/                    # Application logs
├── temp/                    # Temporary files
│
├── install.sh               # Master installer
├── setup.sh                 # Dependency installer
├── run.sh                   # Start script
├── create_service.sh        # Service creator
├── setup_nginx.sh           # Nginx configurator
├── selene-control.sh        # Service controller
└── diagnose.sh              # Diagnostic tool
```

## 🎯 Usage Tips

### Changing AI Models

Selene works with any Ollama model:

```bash
# List available models
ollama list

# Pull a new model
ollama pull llama2

# Update .env
OLLAMA_MODEL=llama2

# Restart Selene
./selene-control.sh restart
```

### Performance Tuning

For better performance on lower-end hardware:

1. Use smaller models: `gemma3:4b` or `qwen2.5:3b`
2. Reduce conversation history in `.env`:
   ```env
   MAX_CONVERSATION_HISTORY=5
   ```
3. Lower TTS cache size:
   ```env
   TTS_CACHE_SIZE=50
   ```

## 🔐 Security Notes

- Selene binds to `0.0.0.0` by default (accessible from network)
- To restrict to localhost only, edit `.env`:
  ```env
  FLASK_HOST=127.0.0.1
  ```
- Consider using a firewall to control access
- For production use, add HTTPS with Let's Encrypt

## 🤝 Contributing

Contributions are welcome! Areas for improvement:

- Additional voice models
- More character expressions
- Voice input support
- Multi-language support
- Custom personality templates

## 📝 License

This project is provided as-is for personal and educational use.

## 🆘 Getting Help

If you encounter issues:

1. Run `./diagnose.sh` for automatic troubleshooting
2. Check logs in `logs/selene.log`
3. Verify Ollama is running: `ollama list`
4. Ensure all dependencies are installed: `python3 -c "import flask, ollama, piper"`

## 🎉 Enjoy!

You now have a fully-functional AI assistant running on your local machine. Chat with Selene and enjoy your privacy-respecting AI companion!

---

<div align="center">

**Made with ❤️ for the Fedora Linux community**

</div>