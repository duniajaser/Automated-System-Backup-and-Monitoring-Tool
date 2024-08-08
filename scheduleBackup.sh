#!/bin/sh

# Default settings
schedule_type=""       # periodic, once, duration
start_datetime=""      # YYYY-MM-DD HH:MM
duration_days=0        # Duration for backups in days
backup_path=""


# Function to display usage
usage() {
    echo "Usage: $0 -t [periodic|once|duration] -d 'YYYY-MM-DD HH:MM' [-l duration_in_days]"
    echo "  -t: Type of schedule"
    echo "  -d: Start date and time (required for periodic and once)"
    echo "  -l: Duration in days (required for duration type)"
    exit 1
}



# Assign passed arguments directly
schedule_type="$1"
start_datetime="$2"
duration_days="$3"  # This assumes that duration_days will always be passed, modify as necessary
backup_path="$4"

# Function to convert datetime for cron usage
convert_datetime() {
    minute=$(date -d "$start_datetime" '+%M')
    hour=$(date -d "$start_datetime" '+%H')
    day=$(date -d "$start_datetime" '+%d')
    month=$(date -d "$start_datetime" '+%m')
    weekday=$(date -d "$start_datetime" '+%u')
}

# Function to schedule the jobs
schedule_backup() {
    convert_datetime
    case $schedule_type in
        periodic)
            # Every week at the specified time
            cron_job="$minute $hour * * $weekday $HOME/Desktop/firstproject/backup_process.sh $backup_path"
            ;;
        once)
            # One-time job at a specific date and time
            cron_job="$minute $hour $day $month * $HOME/Desktop/firstproject/backup_process.sh $backup_path"
            ;;
        duration)
            # Backup starts immediately and runs daily for 'duration_days'
            end_date=$(date -d "$start_datetime +$duration_days days" '+%Y-%m-%d')
            # Split the end_date into day and month components
            end_day=$(date -d "$end_date" '+%d')   
            end_month=$(date -d "$end_date" '+%m')  
            cron_job="$minute $hour * * * $HOME/Desktop/firstproject/backup_process.sh $backup_path"
            end_cron_job="$minute $hour $end_day $end_month * $HOME/Desktop/firstproject/disable_backup.sh $backup_path"  
            ;;
    esac
    # Add the cron job
    (crontab -l 2>/dev/null; echo "$cron_job") | crontab -
    if [ "$schedule_type" = "duration" ]; then
        # Also schedule the end job
        (crontab -l 2>/dev/null; echo "$end_cron_job") | crontab -
    fi
}


# Call the function to schedule the backups
schedule_backup

# Check if duration_days is set and greater than zero
if [ -n "$duration_days" ] && [ "$duration_days" -gt 0 ]; then
    echo "Backup scheduled: $schedule_type starting at $start_datetime for $duration_days days at $backup_path"
else
    echo "Backup scheduled: $schedule_type starting at $start_datetime at $backup_path"
fi


