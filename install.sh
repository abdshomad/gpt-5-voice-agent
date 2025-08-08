#!/bin/bash

# GPT-5 Voice Agent Installation Script
# This script installs dependencies and sets up the environment using uv

set -e  # Exit on any error

echo "🚀 GPT-5 Voice Agent Installation"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if uv is installed
check_uv() {
    print_status "Checking if uv is installed..."
    if ! command -v uv &> /dev/null; then
        print_error "uv is not installed. Please install uv first:"
        echo "curl -LsSf https://astral.sh/uv/install.sh | sh"
        exit 1
    fi
    print_success "uv is installed ($(uv --version))"
}

# Check Python version
check_python() {
    print_status "Checking Python version..."
    if ! uv run python --version &> /dev/null; then
        print_error "Python is not available. Please install Python 3.12+"
        exit 1
    fi
    
    PYTHON_VERSION=$(uv run python --version | cut -d' ' -f2)
    print_success "Python version: $PYTHON_VERSION"
    
    # Check if Python version is 3.12+
    if [[ ! "$PYTHON_VERSION" =~ ^3\.(1[2-9]|[2-9][0-9]) ]]; then
        print_warning "Python version $PYTHON_VERSION detected. Python 3.12+ is recommended."
    fi
}

# Install dependencies
install_dependencies() {
    print_status "Installing dependencies with uv..."
    
    # Sync dependencies
    uv sync
    
    if [ $? -eq 0 ]; then
        print_success "Dependencies installed successfully!"
    else
        print_error "Failed to install dependencies"
        exit 1
    fi
}

# Verify installation
verify_installation() {
    print_status "Verifying installation..."
    
    # Test core dependencies
    uv run python -c "
import openai
import pipecat_ai
import fastapi
import uvicorn
print('✅ Core dependencies verified!')
" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        print_success "Core dependencies are working correctly"
    else
        print_error "Core dependencies verification failed"
        exit 1
    fi
    
    # Test the application
    uv run python gpt-5-voice-agent.py --help &>/dev/null
    if [ $? -eq 0 ]; then
        print_success "Application is ready to run"
    else
        print_warning "Application test failed, but dependencies are installed"
    fi
}

# Setup environment file
setup_env() {
    print_status "Setting up environment file..."
    
    if [ ! -f .env ]; then
        if [ -f .env.example ]; then
            cp .env.example .env
            print_success "Created .env from .env.example"
            print_warning "Please edit .env and add your OpenAI API key"
        else
            print_warning "No .env.example found. Please create .env manually"
        fi
    else
        print_success ".env file already exists"
    fi
}

# Make scripts executable
make_executable() {
    print_status "Making scripts executable..."
    
    chmod +x start.sh stop.sh status.sh 2>/dev/null || true
    print_success "Scripts are executable"
}

# Display next steps
show_next_steps() {
    echo ""
    echo "🎉 Installation Complete!"
    echo "========================"
    echo ""
    echo "Next steps:"
    echo "1. Edit .env file and add your OpenAI API key:"
    echo "   nano .env"
    echo ""
    echo "2. Start the application:"
    echo "   ./start.sh"
    echo ""
    echo "3. Open your browser and go to:"
    echo "   http://localhost:7860/client"
    echo ""
    echo "4. Check status anytime:"
    echo "   ./status.sh"
    echo ""
    echo "5. Stop the application:"
    echo "   ./stop.sh"
    echo ""
    echo "For detailed installation instructions, see INSTALL.md"
    echo ""
}

# Main installation process
main() {
    echo ""
    print_status "Starting GPT-5 Voice Agent installation..."
    echo ""
    
    check_uv
    check_python
    install_dependencies
    verify_installation
    setup_env
    make_executable
    show_next_steps
}

# Run main function
main "$@" 