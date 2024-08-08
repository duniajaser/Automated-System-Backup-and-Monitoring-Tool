#!/bin/sh

# Variables
ALERT_EMAIL="" 
BACKUP_PATH="$HOME/Desktop/backupdirectory/"  # Default backup path, can be overridden with -p option
LOG_FILE="$HOME/Desktop/firstproject/system_logs/system_monitor.log"
MONITOR_SCRIPT="$HOME/Desktop/firstproject/mointerSystem.sh"
BACKUP_DETAILS_FILE="$HOME/Desktop/firstproject/backup_logs/backup_details.log"
PERFORMANCE_FILE="$HOME/Desktop/firstproject/system_logs/system_performance.log"
REPORT_SCRIPT="$HOME/Desktop/firstproject/generateReport.sh"


# Ensure the necessary directories exist
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$(dirname "$BACKUP_DETAILS_FILE")"

# Define log directory and log file for system monitoring
SYSTEM_LOG_DIR="$HOME/Desktop/firstproject/system_logs/"
mkdir -p "$SYSTEM_LOG_DIR"


# Help function
show_help() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -b [type] -d 'YYYY-MM-DD HH:MM' [-t days] -p PATH"
    echo "      Schedule a backup. Types: 'periodic', 'once', or 'duration'."
    echo "      Examples:"
    echo "          $0 -b once -d '2024-01-01 12:00' -p /path/to/backup"
    echo "          $0 -b periodic -d '2024-01-01 12:00' -p /path/to/backup"
    echo "          $0 -b duration -d '2024-01-01 12:00' -t 7 -p /path/to/backup"
    echo "  -u"
    echo "      Unschedule a previously scheduled backup based on the provided path."
    echo "      Example: $0 -u -p /path/to/backup"
    echo "  -l"
    echo "      Display the contents of the system log file."
    echo "      Example: $0 -l"
    echo "  -r"
    echo "      Display a performance report from the system log."
    echo "      Example: $0 -r"
    echo "  -s EMAIL [-d 'YYYY-MM-DD HH:MM'] [-e 'YYYY-MM-DD HH:MM']"
    echo "      Start system monitoring with email alerts. Starts immediately if no start date is provided."
    echo "      Example: $0 -s user@example.com -d '2024-01-01 12:00' -e '2024-01-02 12:00'"
    echo "  -k"
    echo "      Stop system monitoring and remove its process."
    echo "      Example: $0 -k"
    echo "  -j PATH"
    echo "      Perform an immediate backup to the specified path."
    echo "      Example: $0 -j /path/to/backup"
    echo "  -h"
    echo "      Display this help message and exit."
    echo "      Example: $0 -h"
}



# Validate date format explicitly as YYYY-MM-DD HH:MM
validate_date() {
    # Use regex to check if the format matches YYYY-MM-DD HH:MM
    if ! echo "$1" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}$'; then
        echo "Error: Invalid date format. Please use 'YYYY-MM-DD HH:MM'."
        exit 1
    fi

    # Further validate if the date is actually valid
    if ! date -d "$1" >/dev/null 2>&1; then
        echo "Error: The date is not valid."
        exit 1
    fi
}


# Validate email format
validate_email() {
    if ! echo "$1" | grep -E "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$" >/dev/null; then
        echo "Error: Invalid email format."
        exit 1
    fi
}

# Check date is future
check_future_date() {
    local date_to_check=$(date -d "$1" +%s)
    local now=$(date +%s)
    if [ "$date_to_check" -le "$now" ]; then
        echo "Error: The date '$1' must be in the future."
        exit 1
    fi
}

# Check end date is greater than start date
validate_start_end_dates() {
    local start=$(date -d "$1" +%s)
    local end=$(date -d "$2" +%s)
    if [ "$end" -le "$start" ]; then
        echo "Error: The end date '$2' must be later than the start date '$1'."
        exit 1
    fi
}


# Function to display log content
display_logs() {
    echo "Displaying Log Contents:"
    tail -n 10 "$LOG_FILE"
}

# Function to generate a performance report
generate_report() {
    echo "Displaying Performance Report:"
    cat "$PERFORMANCE_FILE"
}

unschedule_report() {
    (crontab -l 2>/dev/null | grep -v "$REPORT_SCRIPT") | crontab -
    echo "Report generation unscheduled."
}

# Function to schedule daily report generation
schedule_daily_report() {
    # Set the time for the cron job, e.g., at 7 PM every day
    local cron_time="0 19 * * *"
    
    # Add the cron job to the crontab without redirection here
    (crontab -l 2>/dev/null; echo "$cron_time /bin/sh $REPORT_SCRIPT") | crontab -
    echo "Daily report generation scheduled."
}




CURRENT_TIME=$(date +%s)

# Function to start system monitoring
start_monitoring() {
    local start_date="$1"
    local end_date="$2"
    local command="$MONITOR_SCRIPT $ALERT_EMAIL"
    
    [ -n "$start_date" ] && validate_date "$start_date"
    [ -n "$end_date" ] && validate_date "$end_date"
    [ -n "$ALERT_EMAIL" ] && validate_email "$ALERT_EMAIL"

    check_future_date "$start_date"
    [ -n "$end_date" ] && validate_start_end_dates "$start_date" "$end_date"
    

    if [ -n "$start_date" ]; then
        # Format the start date for the 'at' command using a reliable method
        local formatted_start_date=$(date -d "$start_date" '+%Y%m%d%H%M')

        # Schedule the initial execution with 'at' using the precise format
        echo "$command" | at -t "$formatted_start_date" 2>/dev/null
        echo "Monitoring scheduled to start at $start_date."

        # Schedule the cron job to start right after the initial 'at' job
        local at_time=$(date -d "$start_date" '+%H:%M %m/%d/%Y')
        echo "(crontab -l 2>/dev/null; echo \"*/3 * * * * $command\") | crontab -" | at "$at_time" 2>/dev/null
        echo "Repeating monitoring every 3 minutes after initial start."
    else
        # Immediate start without a specific start date
        local cron_entry="*/3 * * * * $command"
        (crontab -l 2>/dev/null; echo "$cron_entry") | crontab -
        echo "Monitoring started immediately, repeating every 3 minutes."
    fi

    if [ -n "$end_date" ]; then
        # Schedule a job to stop the monitoring at the end date
        local formatted_end_date=$(date -d "$end_date" '+%Y%m%d%H%M')
        echo "crontab -l | grep -v '$command' | crontab -" | at -t "$formatted_end_date" 2>/dev/null
        echo "Monitoring scheduled to end at $end_date."
    fi
    
    schedule_daily_report
}



# Function to stop system monitoring immediately
stop_monitoring() {
    # Remove the specific cron job that starts the monitoring script
    (crontab -l 2>/dev/null | grep -v "$MONITOR_SCRIPT") | crontab -
    echo "Monitoring stopped."
}

validate_backup_type() {
    case "$1" in
        periodic|once|duration) return 0 ;;
        *) echo "Error: Invalid backup type. Use 'periodic', 'once', or 'duration'."; exit 1 ;;
    esac
}

validate_backup_parameters() {
    if [ "$schedule_type" = "duration" ] && [ -z "$duration_days" ]; then
        echo "Error: 'duration_days' required for duration type backup."
        exit 1
    fi
}

# Function to validate backup path
validate_backup_path() {
    if [ ! -d "$1" ] || [ ! -w "$1" ]; then
        echo "Error: Backup path '$1' does not exist or is not writable."
        exit 1
    fi
}


# Parse command-line options
schedule_type=""
start_datetime=""
duration_days="0"
end_datetime=""
start_monitoring_time=""
end_monitoring_time=""

# Parse command-line options
while getopts 'hb:d:t:p:lrs:d:e:kju' OPTION; do
    case "$OPTION" in
        b) schedule_type="$OPTARG" ;;  # Backup type
        d) start_datetime="$OPTARG" ;;  # Start date for monitoring or backup
        t) duration_days="$OPTARG" ;;  # Duration in days for duration type backup
        p) BACKUP_PATH="$OPTARG" ;;  # Path for backup
        l) display_logs; exit 0 ;;  # Display logs
        r) generate_report; exit 0 ;;  # Display performance report
        s) ALERT_EMAIL="$OPTARG" ;;
        e) end_monitoring_time="$OPTARG" ;;  # Optional end time for monitoring
        k) stop_monitoring; exit 0 ;;  # Stop monitoring
        j) BACKUP_PATH="$OPTARG"; backup_system; exit 0 ;;  # Perform immediate backup
        u) unschedule_backup; exit 0 ;;  # Unschedule a backup
        h) show_help; exit 0 ;;  # Show help
        ?) show_help; exit 1 ;;  # Show help for invalid option
    esac
done


# Default behavior: show help if no options were provided
if [ $OPTIND -eq 1 ]; then
    show_help
    exit 0
fi


# Check if scheduling parameters are provided
if [ -n "$schedule_type" ] && [ -n "$start_datetime" ]; then

    validate_date "$start_datetime"
    check_future_date "$start_datetime"
    
    validate_backup_type "$schedule_type"
    validate_backup_parameters
    
    validate_backup_path "$BACKUP_PATH"

    # Call schedule.sh with the required parameters
    "$HOME/Desktop/firstproject/scheduleBackup.sh" "$schedule_type" "$start_datetime" "$duration_days" "$BACKUP_PATH"
    exit 0
fi

# Check if scheduling parameters are provided
if [ -n "$ALERT_EMAIL" ]; then
    # Call schedule.sh with the required parameters
    start_monitoring "$start_datetime" "$end_datetime"  # Start monitoring with email alerts
    exit  0
fi


backup_system() {
    validate_backup_path "$BACKUP_PATH"
    "$HOME/Desktop/firstproject/backup_process.sh" "$BACKUP_PATH"
}

# Function to remove a specific schedule
unschedule_backup() {
    local job_marker="$BACKUP_PATH"  
    # Capture current cron jobs into a variable
    local current_crontab=$(crontab -l)
    local modified_crontab

    # Filter out the job marker from the crontab
    modified_crontab=$(echo "$current_crontab" | grep -v "$job_marker")

    # Compare the modified crontab with the current crontab
    if [ "$current_crontab" != "$modified_crontab" ]; then
        # If different, job marker was found and removed
        echo "Found scheduled backup for $BACKUP_PATH. Removing..."
        echo "$modified_crontab" | crontab -
        echo "Scheduled backup removed."
    else
        # If not different, no job marker was found
        echo "No scheduled backup found for $BACKUP_PATH."
    fi
}


