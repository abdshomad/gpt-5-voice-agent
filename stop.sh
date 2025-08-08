#!/bin/bash

# GPT-5 Voice Agent Stop Script
# This script stops the voice agent app using PID file

PID_FILE="app.pid"
LOG_FILE="app.log"

echo "Stopping GPT-5 Voice Agent..."

# Check if PID file exists
if [ ! -f "$PID_FILE" ]; then
    echo "ℹ️  No PID file found. Checking for running processes..."
    
    # Try to find and kill by process name
    if pgrep -f "gpt-5-voice-agent.py" > /dev/null; then
        echo "Found running app process..."
        pkill -f "gpt-5-voice-agent.py"
        sleep 2
        
        if pgrep -f "gpt-5-voice-agent.py" > /dev/null; then
            echo "Process still running, force killing..."
            pkill -9 -f "gpt-5-voice-agent.py"
        fi
        
        echo "✅ App stopped successfully!"
    else
        echo "ℹ️  No running app found."
    fi
else
    # Read PID from file
    APP_PID=$(cat "$PID_FILE")
    echo "Found PID file with PID: $APP_PID"
    
    # Check if process is still running
    if ps -p $APP_PID > /dev/null 2>&1; then
        echo "Stopping process with PID: $APP_PID"
        kill $APP_PID
        sleep 2
        
        # Check if process is still running
        if ps -p $APP_PID > /dev/null 2>&1; then
            echo "Process still running, force killing..."
            kill -9 $APP_PID
            sleep 1
        fi
        
        # Final check
        if ps -p $APP_PID > /dev/null 2>&1; then
            echo "❌ Failed to stop the app. Process is still running."
            exit 1
        else
            echo "✅ App stopped successfully!"
        fi
    else
        echo "ℹ️  Process with PID $APP_PID is not running."
    fi
    
    # Remove PID file
    rm -f "$PID_FILE"
    echo "📊 PID file removed."
fi

# Check if port 7860 is still in use
if lsof -i :7860 > /dev/null 2>&1; then
    echo "⚠️  Port 7860 is still in use by another process."
    echo "   You may need to manually stop it if it's not the voice agent."
else
    echo "✅ Port 7860 is now free."
fi

echo "📝 Log file: $LOG_FILE" 