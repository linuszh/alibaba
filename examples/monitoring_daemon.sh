#!/bin/bash
# Example: Set up continuous monitoring as a background daemon

PRODUCT="$1"
INTERVAL="${2:-300}"  # Default 5 minutes

if [ -z "$PRODUCT" ]; then
    echo "Usage: $0 \"product keywords\" [interval_seconds]"
    echo "Example: $0 \"usb cables\" 600"
    exit 1
fi

echo "Starting monitoring daemon for: $PRODUCT"
echo "Interval: $INTERVAL seconds"

# Run monitoring in background
nohup ../alibaba-search monitor "$PRODUCT" --interval $INTERVAL > monitor_${PRODUCT// /_}.log 2>&1 &

PID=$!
echo "Monitoring started with PID: $PID"
echo $PID > monitor_${PRODUCT// /_}.pid

echo "To stop: kill \$(cat monitor_${PRODUCT// /_}.pid)"
