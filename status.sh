#!/bin/bash

# GPT-5 Voice Agent Status Script
# This script checks the status of the voice agent app

PID_FILE="app.pid"
LOG_FILE="app.log"

echo "GPT-5 Voice Agent Status"
echo "========================"

# Check if PID file exists
if [ -f "$PID_FILE" ]; then
    APP_PID=$(cat "$PID_FILE")
    echo "📊 PID File: $PID_FILE (PID: $APP_PID)"
    
    # Check if process is running
    if ps -p $APP_PID > /dev/null 2>&1; then
        echo "✅ Status: RUNNING"
        echo "🌐 URL: http://localhost:7860/client"
        echo "📝 Logs: $LOG_FILE"
        echo "🛑 Stop: ./stop.sh"
        
        # Show recent logs
        if [ -f "$LOG_FILE" ]; then
            echo ""
            echo "📋 Recent logs (last 5 lines):"
            echo "--------------------------------"
            tail -5 "$LOG_FILE" 2>/dev/null || echo "No logs available"
        fi
    else
        echo "❌ Status: NOT RUNNING (stale PID file)"
        echo "🧹 Cleaning up stale PID file..."
        rm -f "$PID_FILE"
    fi
else
    echo "📊 PID File: Not found"
    
    # Check if process is running by name
    if pgrep -f "gpt-5-voice-agent.py" > /dev/null; then
        RUNNING_PID=$(pgrep -f "gpt-5-voice-agent.py")
        echo "✅ Status: RUNNING (PID: $RUNNING_PID)"
        echo "🌐 URL: http://localhost:7860/client"
        echo "🛑 Stop: ./stop.sh"
    else
        echo "❌ Status: NOT RUNNING"
        echo "🚀 Start: ./run.sh"
    fi
fi

# Check port status
echo ""
echo "🔌 Port Status:"
if lsof -i :7860 > /dev/null 2>&1; then
    PORT_PID=$(lsof -ti :7860)
    echo "✅ Port 7860: IN USE (PID: $PORT_PID)"
else
    echo "❌ Port 7860: FREE"
fi 