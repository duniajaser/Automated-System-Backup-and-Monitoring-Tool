#!/bin/sh

# Variables
CPU_THRESHOLD=80
MEM_THRESHOLD=90
DISK_THRESHOLD=85
LOG_FILE="$HOME/Desktop/firstproject/system_logs/system_monitor.log"
ALERT_EMAIL=$1  # Alert email is passed as a command-line argument


# Ensure the log directory exists
LOG_DIR=$(dirname "$LOG_FILE")
mkdir -p "$LOG_DIR"

CPU_ALERT_TIME_FILE="$LOG_DIR/cpu_alert_time.log"
MEM_ALERT_TIME_FILE="$LOG_DIR/mem_alert_time.log"
DISK_ALERT_TIME_FILE="$LOG_DIR/disk_alert_time.log"



# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') Information - $1" >> "$LOG_FILE"
}


# Check if an email address is provided
if [ -z "$ALERT_EMAIL" ]; then
    echo "Error: No email address provided."
    echo "Usage: $0 <email-address>"
    exit 1
fi


send_alert_if_needed() {
    local current_time=$(date +%s)  # Current time in seconds since the epoch
    local last_alert_time_file=$1
    local current_usage=$2
    local alert_threshold=$3
    local usage_type=$4
    local formatted_time=$(date '+%Y-%m-%d %H:%M:%S')

    # Read the last alert time from file, default to 0 if not set
    local last_alert_time=$(cat "$last_alert_time_file" 2>/dev/null || echo 0)

    # Calculate the time difference
    local time_diff=$((current_time - last_alert_time))

    # Check if the last alert time file exists and has a non-zero value, or handle first alert
    if [ ! -s "$last_alert_time_file" ] || [ "$last_alert_time" -eq 0 ]; then
        # If file doesn't exist or time is zero, consider it as the first alert scenario
        echo "First time alert or reset for $usage_type. Setting initial alert timestamp."
        echo "$current_time" > "$last_alert_time_file"
    fi

    # Check if alert should be sent (20 min = 1200 seconds example)
    if [ "$time_diff" -gt 1200 ] && [ $(echo "$current_usage > $alert_threshold" | bc) -eq 1 ]; then
       local alert_message="$formatted_time Warning: $usage_type usage is above normal threshold at $current_usage%"
        echo "$alert_message" >> "$LOG_FILE"
        echo "----------------------------------------------------" >> "$LOG_FILE"
        echo "$alert_message" | mail -s "High $usage_type Usage Alert" "$ALERT_EMAIL"
        echo "$current_time" > "$last_alert_time_file"
    fi
}



# Function to perform all system checks and log them in one line
check_system() {

    # Gather CPU Usage
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    if [ $(echo "$CPU_USAGE > $CPU_THRESHOLD" | bc) -eq 1 ]; then
        #echo "ALERT: High CPU usage detected: $CPU_USAGE%" | mail -s "High CPU Usage Alert" "$ALERT_EMAIL"
        send_alert_if_needed "$CPU_ALERT_TIME_FILE" "$CPU_USAGE" "$CPU_THRESHOLD" "CPU"

    fi
    
    # Gather Memory Usage
    MEM_USAGE=$(free -m | awk 'NR==2{printf "%s", $3*100/$2}')
    if [ $(echo "$MEM_USAGE > $MEM_THRESHOLD" | bc) -eq 1 ]; then
        #echo "ALERT: High Memory usage detected: $MEM_USAGE%" | mail -s "High Memory Usage Alert" "$ALERT_EMAIL"
        send_alert_if_needed "$MEM_ALERT_TIME_FILE" "$MEM_USAGE" "$MEM_THRESHOLD" "Memory"

    fi

    # Gather Disk Usage
    DISK_USAGE=$(df / | grep / | awk '{print $5}' | sed 's/%//g')
    if [ "$DISK_USAGE" -gt "$DISK_THRESHOLD" ]; then
        #echo "ALERT: High Disk usage detected: $DISK_USAGE%" | mail -s "High Disk Usage Alert" "$ALERT_EMAIL"
        send_alert_if_needed "$DISK_ALERT_TIME_FILE" "$DISK_USAGE" "$DISK_THRESHOLD" "Disk"

    fi

    # Gather Network Activity
    INTERFACE=$(ip link | awk -F': ' '/^[0-9]+: / {print $2}' | grep -v lo | head -n 1)
    RX_BYTES_BEFORE=$(cat /sys/class/net/"$INTERFACE"/statistics/rx_bytes)
    TX_BYTES_BEFORE=$(cat /sys/class/net/"$INTERFACE"/statistics/tx_bytes)
    sleep 1
    RX_BYTES_AFTER=$(cat /sys/class/net/"$INTERFACE"/statistics/rx_bytes)
    TX_BYTES_AFTER=$(cat /sys/class/net/"$INTERFACE"/statistics/tx_bytes)
    RX_RATE=$(((RX_BYTES_AFTER - RX_BYTES_BEFORE) / 1024))
    TX_RATE=$(((TX_BYTES_AFTER - TX_BYTES_BEFORE) / 1024))

    # Combine all metrics into one log entry
    log "CPU: ${CPU_USAGE}% | Mem: ${MEM_USAGE}% | Disk: ${DISK_USAGE}% | Net: RX ${RX_RATE}KB/s, TX ${TX_RATE}KB/s"
    echo "----------------------------------------------------" >> "$LOG_FILE"

}

# Execute system checks
check_system



