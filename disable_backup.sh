#!/bin/sh

# Identify the script or command you want to remove from cron
backup_script="$1"

# Print existing cron jobs (for debugging)
echo "Current cron jobs before removal:"
crontab -l

# Remove specific cron job related to the backup script
crontab -l | grep -v "$backup_script" | crontab -

# Confirmation message
echo "Backup jobs involving $backup_script have been disabled."
echo "Updated cron jobs:"
crontab -l

