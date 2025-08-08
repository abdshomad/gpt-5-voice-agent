#!/bin/bash

# GPT-5 Voice Agent Runner Script
# This script runs the voice agent app in the background using uv

PID_FILE="app.pid"
LOG_FILE="app.log"

echo "Starting GPT-5 Voice Agent..."

# Check if the app is already running
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if ps -p $OLD_PID > /dev/null 2>&1; then
        echo "App is already running with PID: $OLD_PID"
        echo "🌐 Open http://localhost:7860/client in your browser"
        echo "🛑 To stop the app, run: ./stop.sh"
        exit 0
    else
        echo "Removing stale PID file..."
        rm -f "$PID_FILE"
    fi
fi

# Check if port 7860 is already in use
if lsof -i :7860 > /dev/null 2>&1; then
    echo "Port 7860 is already in use. Stopping existing process..."
    pkill -f "gpt-5-voice-agent.py"
    sleep 2
fi

# Run the app in the background
echo "Starting the app with uv..."
uv run gpt-5-voice-agent.py > "$LOG_FILE" 2>&1 &

# Get the process ID and save it
APP_PID=$!
echo $APP_PID > "$PID_FILE"
echo "App started with PID: $APP_PID"

# Wait a moment for the app to start
sleep 3

# Check if the app is running
if ps -p $APP_PID > /dev/null; then
    echo "✅ App is running successfully!"
    echo "🌐 Open http://localhost:7860/client in your browser"
    echo "📝 Logs are being written to $LOG_FILE"
    echo "🛑 To stop the app, run: ./stop.sh"
    echo "📊 PID saved to: $PID_FILE"
else
    echo "❌ Failed to start the app. Check $LOG_FILE for details."
    rm -f "$PID_FILE"
    exit 1
fi 