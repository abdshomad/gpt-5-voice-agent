# Installation Guide - GPT-5 Voice Agent

This guide provides step-by-step instructions for installing and setting up the GPT-5 Voice Agent on your system.

## 📋 Prerequisites

### System Requirements

- **Operating System**: macOS, Linux, or Windows (WSL recommended for Windows)
- **Python**: 3.12 or higher
- **Memory**: Minimum 4GB RAM (8GB recommended)
- **Storage**: At least 2GB free space
- **Network**: Stable internet connection for API calls

### Required Software

1. **Python 3.12+**
   ```bash
   # Check your Python version
   python3 --version
   
   # If you need to install Python 3.12+
   # macOS (using Homebrew)
   brew install python@3.12
   
   # Ubuntu/Debian
   sudo apt update
   sudo apt install python3.12 python3.12-venv
   
   # Windows (download from python.org)
   # https://www.python.org/downloads/
   ```

2. **uv Package Manager**
   ```bash
   # Install uv (recommended package manager)
   curl -LsSf https://astral.sh/uv/install.sh | sh
   
   # Or using pip
   pip install uv
   
   # Verify installation
   uv --version
   ```

3. **Git** (for cloning the repository)
   ```bash
   # macOS
   brew install git
   
   # Ubuntu/Debian
   sudo apt install git
   
   # Windows (download from git-scm.com)
   # https://git-scm.com/download/win
   ```

## 🚀 Installation Steps

### Step 1: Clone the Repository

```bash
# Clone the repository
git clone https://github.com/abdshomad/gpt-5-voice-agent.git
cd gpt-5-voice-agent

# Or if you have the files locally, navigate to the project directory
cd gpt-5-voice-agent-2025
```

### Step 2: Automated Installation (Recommended)

```bash
# Run the automated installer
./install.sh
```

The installer will:
- ✅ Check if `uv` is installed
- ✅ Verify Python version (3.12+ recommended)
- ✅ Install all dependencies using `uv sync`
- ✅ Verify core dependencies
- ✅ Set up environment file from template
- ✅ Make scripts executable
- ✅ Provide next steps guidance

### Step 3: Manual Installation (Alternative)

If you prefer manual installation:

```bash
# Install all dependencies using uv
uv sync

# Or install with pip (alternative)
pip install -e .

# Verify installation
uv run python -c "import openai, pipecat_ai; print('Dependencies installed successfully!')"
```

**Note**: The project uses `pyproject.toml` for dependency management, which provides better dependency resolution and project metadata.

### Step 4: Configure Environment Variables

```bash
# Copy the example environment file
cp .env.example .env

# Edit the environment file with your API key
nano .env  # or use your preferred editor
```

**Required Configuration in `.env`:**

```bash
# OpenAI API Configuration
OPENAI_API_KEY=sk_proj-your-actual-api-key-here

# Optional Configuration
DEBUG=false
PORT=7860
```

### Step 5: Get OpenAI API Key

1. **Create OpenAI Account** (if you don't have one):
   - Go to [OpenAI Platform](https://platform.openai.com/)
   - Sign up or log in

2. **Generate API Key**:
   - Navigate to [API Keys](https://platform.openai.com/api-keys)
   - Click "Create new secret key"
   - Copy the key (starts with `sk_proj-`)

3. **Add to Environment**:
   - Open `.env` file
   - Replace `sk_proj-your-actual-api-key-here` with your actual key
   - Save the file

### Step 6: Verify Installation

```bash
# Test the installation
uv run python gpt-5-voice-agent.py --help

# Check if all dependencies are available
uv run python -c "
import openai
import pipecat_ai
import fastapi
import uvicorn
print('✅ All dependencies installed successfully!')
"

# Or run the automated verification
./install.sh  # This will verify everything automatically
```

## 🔧 Platform-Specific Instructions

### macOS Installation

```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Python and uv
brew install python@3.12
curl -LsSf https://astral.sh/uv/install.sh | sh

# Follow the general installation steps above
```

### Ubuntu/Debian Installation

```bash
# Update package list
sudo apt update

# Install Python 3.12 and pip
sudo apt install python3.12 python3.12-venv python3.12-pip

# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Add uv to PATH (add to ~/.bashrc or ~/.zshrc)
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Follow the general installation steps above
```

### Windows Installation

#### Option 1: Using WSL (Recommended)

```bash
# Install WSL2
wsl --install

# Install Ubuntu on WSL
wsl --install -d Ubuntu

# Follow Ubuntu installation steps above
```

#### Option 2: Native Windows

```bash
# Install Python from python.org
# Download and install Python 3.12+

# Install uv using pip
pip install uv

# Follow the general installation steps above
# Use Windows command prompt or PowerShell
```

## 🧪 Testing the Installation

### Quick Test

```bash
# Run the automated installer (if not already done)
./install.sh

# Start the application
./start.sh

# Check if it's running
./status.sh

# Stop the application
./stop.sh
```

### Browser Test

1. **Start the application**:
   ```bash
   ./start.sh
   ```

2. **Open browser**:
   - Navigate to: http://localhost:7860/client
   - Allow camera and microphone permissions

3. **Test voice interaction**:
   - Speak into your microphone
   - Check if the AI responds

## 🔍 Troubleshooting

### Common Issues

#### 1. Python Version Issues
```bash
# Check Python version
python3 --version

# If version is < 3.12, upgrade:
# macOS
brew install python@3.12

# Ubuntu
sudo apt install python3.12
```

#### 2. uv Installation Issues
```bash
# Alternative installation methods
pip install uv

# Or using cargo (if you have Rust installed)
cargo install uv
```

#### 3. Permission Issues
```bash
# Make scripts executable
chmod +x start.sh stop.sh status.sh

# Check file permissions
ls -la *.sh
```

#### 4. Port Already in Use
```bash
# Check what's using port 7860
lsof -i :7860

# Kill the process
kill -9 <PID>

# Or change port in .env
echo "PORT=7861" >> .env
```

#### 5. API Key Issues
```bash
# Verify API key format
grep "sk_proj-" .env

# Test API key
uv run python -c "
import openai
import os
from dotenv import load_dotenv
load_dotenv()
client = openai.OpenAI(api_key=os.getenv('OPENAI_API_KEY'))
try:
    models = client.models.list()
    print('✅ API key is valid!')
except Exception as e:
    print(f'❌ API key error: {e}')
"
```

#### 6. Dependencies Issues
```bash
# Reinstall dependencies
uv sync --reinstall

# Clear cache and reinstall
uv cache clean
uv sync
```

#### 7. Audio/Video Issues
- **Browser Permissions**: Ensure camera and microphone access is granted
- **Hardware**: Check if microphone and camera are working in other applications
- **Browser**: Try Chrome or Firefox (Safari may have issues)

### Debug Mode

```bash
# Enable debug logging
echo "DEBUG=true" >> .env

# Start with debug output
uv run python gpt-5-voice-agent.py

# Check logs
tail -f app.log
```

## 📚 Additional Resources

- **OpenAI API Documentation**: https://platform.openai.com/docs
- **Pipecat Documentation**: https://docs.pipecat.ai/
- **uv Documentation**: https://docs.astral.sh/uv/
- **WebRTC Documentation**: https://webrtc.org/

## 🆘 Getting Help

If you encounter issues:

1. **Check the logs**: `tail -f app.log`
2. **Verify installation**: Run the test commands above
3. **Check system requirements**: Ensure all prerequisites are met
4. **Review troubleshooting section**: Common solutions are listed above
5. **Open an issue**: Create a GitHub issue with detailed error information

## ✅ Installation Checklist

- [ ] Python 3.12+ installed
- [ ] uv package manager installed
- [ ] Repository cloned
- [ ] Virtual environment created and activated
- [ ] Dependencies installed (`uv sync`)
- [ ] Environment file created (`.env`)
- [ ] OpenAI API key configured
- [ ] Scripts made executable (`chmod +x *.sh`)
- [ ] Application starts successfully (`./start.sh`)
- [ ] Browser can access http://localhost:7860/client
- [ ] Voice interaction works
- [ ] Video stream works

**Congratulations! 🎉 Your GPT-5 Voice Agent is now installed and ready to use!** 