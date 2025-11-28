"""
Selene AI Assistant - Main Entry Point
A Fedora Linux AI Assistant with Piper TTS and Phoneme-Based Lip Sync

Requirements:
pip install flask flask-cors ollama piper-tts pillow g2p-en numpy python-dotenv

Directory structure:
assistant.py (this file)
.env (configuration file)
modules/
    utils.py
    phonemes.py
    tts.py
    api.py
"""

import logging
import sys
from flask import Flask
from flask_cors import CORS
import ollama

# Import modules
from modules.utils import Config, setup_logging
from modules.tts import initialize_piper_tts, PIPER_TTS_AVAILABLE, piper_voice
from modules.phonemes import G2P_AVAILABLE
from modules.api import register_routes

logger = logging.getLogger(__name__)


def create_app():
    """
    Flask application factory
    
    Returns:
        Configured Flask application
    """
    # Setup logging first
    setup_logging()
    
    # Validate configuration
    is_valid, errors = Config.validate()
    if not is_valid:
        logger.error("Configuration validation failed:")
        for error in errors:
            logger.error(f"  - {error}")
        sys.exit(1)
    
    # Ensure required directories exist
    Config.ensure_directories()
    
    # Initialize Flask app
    app = Flask(__name__)
    app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max request size
    
    # Enable CORS
    CORS(app)
    
    # Register all routes
    register_routes(app)
    
    return app


def check_dependencies():
    """Check and display status of all dependencies"""
    print("\n" + "="*60)
    print("🚀 Selene - Fedora Linux AI Assistant (Piper TTS)")
    print("="*60)
    
    # Check Ollama
    try:
        models = ollama.list()
        print(f"[OK] Ollama connected ({Config.OLLAMA_BASE_URL})")
        model_list = [m.get('name', m.get('model', '')) for m in models.get('models', [])]
        print(f"[OK] Available models: {model_list}")
        
        # FIXED: Check against full model names instead of just the base name
        if Config.OLLAMA_MODEL not in model_list:
            logger.warning(f"Configured model '{Config.OLLAMA_MODEL}' not found in available models")
    except Exception as e:
        print(f"[ERROR] Ollama connection failed: {e}")
        print(f"  Make sure Ollama is running at {Config.OLLAMA_BASE_URL}")
        logger.error(f"Ollama connection error: {e}")
    
    # Check Piper TTS
    if PIPER_TTS_AVAILABLE and piper_voice:
        print(f"[OK] Piper TTS (neural) available")
        print(f"  Model: {Config.PIPER_MODEL_NAME}")
    else:
        print("[ERROR] Piper TTS not available or model not loaded")
        print("  Install: pip install piper-tts")
        print(f"\n  Download voice models to: {Config.PIPER_MODELS_DIR}")
        print("  1. Visit: https://github.com/rhasspy/piper/releases/tag/v1.2.0")
        print(f"  2. Download {Config.PIPER_MODEL_NAME}.onnx and {Config.PIPER_MODEL_NAME}.onnx.json")
        print(f"  3. Place them in '{Config.PIPER_MODELS_DIR}' directory")
    
    # Check g2p-en
    if G2P_AVAILABLE:
        print("[OK] Phoneme-based Lip Sync enabled (g2p-en)")
    else:
        print("[WARNING] g2p-en not available - using timing-based fallback")
        print("  Install: pip install g2p-en")
    
    # Configuration info
    print("\n" + "="*60)
    print("📋 Configuration")
    print("="*60)
    print(f"Assistant Name: {Config.ASSISTANT_NAME}")
    print(f"Birthday: {Config.ASSISTANT_BIRTHDAY.strftime('%B %d, %Y')}")
    print(f"Model: {Config.OLLAMA_MODEL}")
    print(f"Max History: {Config.MAX_CONVERSATION_HISTORY} messages")
    print(f"Log Level: {Config.LOG_LEVEL}")
    print(f"Log File: {Config.LOG_FILE}")
    
    # Show localhost URL instead of 0.0.0.0
    display_host = "localhost" if Config.FLASK_HOST == "0.0.0.0" else Config.FLASK_HOST
    
    print("\n" + "="*60)
    print(f"🌐 Server starting at: http://{display_host}:{Config.FLASK_PORT}")
    print("="*60)
    print(f"🔊 TTS: {'ENABLED (Piper - Neural)' if PIPER_TTS_AVAILABLE else 'DISABLED'}")
    print(f"💄 Lip Sync: {'PHONEME-BASED' if G2P_AVAILABLE else 'TIMING-BASED'}")
    print("\nPress Ctrl+C to stop the server")
    print("\n" + "="*60)
    print("💬 Chat conversation will appear below")
    print("="*60 + "\n")


if __name__ == '__main__':
    try:
        # Check dependencies and show status
        check_dependencies()
        
        # Create Flask app using factory pattern
        app = create_app()
        
        # Run the application
        app.run(
            host=Config.FLASK_HOST,
            port=Config.FLASK_PORT,
            debug=Config.FLASK_DEBUG,
            use_reloader=False
        )
    except KeyboardInterrupt:
        print("\n\n👋 Shutting down Selene...")
        sys.exit(0)
    except Exception as e:
        logger.error(f"Failed to start application: {e}", exc_info=True)
        print(f"\n❌ Failed to start: {e}")
        sys.exit(1)
