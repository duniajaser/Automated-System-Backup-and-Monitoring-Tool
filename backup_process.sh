#!/bin/sh

# Variables
BACKUP_PATH="$1"  # Pass the backup directory path as an argument
LOG_FILE="$HOME/Desktop/firstproject/system_logs/system_monitor.log"

# Ensure the backup directory exists
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$BACKUP_PATH"

backup_system() {
    local actual_start=$(date '+%Y-%m-%d %H:%M:%S')
    local day_of_week=$(date '+%A')
    local version=$(date '+%Y%m%d_%H%M%S')
    local backup_file="$BACKUP_PATH/backup_$version.tar.gz"

    echo "Backup starting at: $actual_start on $day_of_week" >> "$LOG_FILE"
    tar_output=$(tar -czf "$backup_file" -C "$BACKUP_PATH" . 2>&1)
    tar_status=$?

    local actual_end=$(date '+%Y-%m-%d %H:%M:%S')
    if [ $tar_status -eq 0 ]; then
      #  echo "Backup completed successfully at $version."
        echo "Backup ended at: $actual_end on $day_of_week" >> "$LOG_FILE"
        echo "$actual_start, $actual_end, $day_of_week - Backup successful." >> "$LOG_FILE"
    else
       # echo "Backup encountered issues: $tar_output"
        echo "$actual_start, $actual_end, $day_of_week - Backup encountered issues." >> "$LOG_FILE"
        exit 1
    fi
    
    echo "----------------------------------------------------" >> "$LOG_FILE"
    
}

# Execute the backup
backup_system

