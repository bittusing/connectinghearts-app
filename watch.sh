#!/bin/bash
# Flutter Watch Script (like nodemon)
# This script watches for file changes and automatically restarts Flutter

PROJECT_PATH="$(cd "$(dirname "$0")" && pwd)"
FLUTTER_PID=""

start_flutter() {
    echo "Starting Flutter..."
    cd "$PROJECT_PATH"
    flutter run &
    FLUTTER_PID=$!
}

stop_flutter() {
    if [ ! -z "$FLUTTER_PID" ] && kill -0 "$FLUTTER_PID" 2>/dev/null; then
        echo "Stopping Flutter..."
        kill "$FLUTTER_PID" 2>/dev/null
        wait "$FLUTTER_PID" 2>/dev/null
    fi
}

restart_flutter() {
    stop_flutter
    sleep 1
    start_flutter
}

# Cleanup on exit
trap 'stop_flutter; exit' INT TERM

# Start Flutter initially
start_flutter

echo ""
echo "Flutter watch mode is running. Press Ctrl+C to stop."
echo "Watching for changes in: $PROJECT_PATH/lib"

# Watch for file changes using inotifywait (Linux) or fswatch (macOS)
if command -v inotifywait &> /dev/null; then
    # Linux
    inotifywait -m -r -e modify,create,delete --format '%e %f' "$PROJECT_PATH/lib" | while read event file; do
        echo ""
        echo "[$event] $file"
        echo "Restarting Flutter..."
        restart_flutter
    done
elif command -v fswatch &> /dev/null; then
    # macOS
    fswatch -o "$PROJECT_PATH/lib" | while read f; do
        echo ""
        echo "[CHANGED] Detected file change"
        echo "Restarting Flutter..."
        restart_flutter
    done
else
    echo "Error: inotifywait (Linux) or fswatch (macOS) not found."
    echo "Please install one of them to enable file watching."
    exit 1
fi

