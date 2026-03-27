#!/bin/bash

LOG_FILE="/var/log/health_monitor.log"
SERVICE_FILE="services.txt"
DRY_RUN=false

# Check for --dry-run flag
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
fi

# Counters
total=0
healthy=0
recovered=0
failed=0

# Check if services.txt exists
if [[ ! -f "$SERVICE_FILE" || ! -s "$SERVICE_FILE" ]]; then
    echo "Error: services.txt missing or empty"
    exit 1
fi

echo "Starting Service Health Monitor..."

while read -r service
do
    ((total++))

    status=$(systemctl is-active "$service" 2>/dev/null)

    if [[ "$status" == "active" ]]; then
        ((healthy++))
        echo "$service is running"
    else
        echo "$service is NOT running. Attempting restart..."

        if [[ "$DRY_RUN" == true ]]; then
            echo "[DRY RUN] Would restart $service"
            continue
        fi

        sudo systemctl restart "$service"
        sleep 5

        new_status=$(systemctl is-active "$service" 2>/dev/null)

        if [[ "$new_status" == "active" ]]; then
            ((recovered++))
            echo "$(date) [INFO] $service RECOVERED" | sudo tee -a $LOG_FILE
        else
            ((failed++))
            echo "$(date) [ERROR] $service FAILED" | sudo tee -a $LOG_FILE
        fi
    fi

done < "$SERVICE_FILE"

echo "Summary:"
echo "Total Checked: $total"
echo "Healthy: $healthy"
echo "Recovered: $recovered"
echo "Failed: $failed"
