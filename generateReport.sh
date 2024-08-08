#!/bin/sh

LOG_FILE="$HOME/Desktop/firstproject/system_logs/system_performance.log"
LOG_FILE_MONITOR="$HOME/Desktop/firstproject/system_logs/system_monitor.log"

# Function to create a log file if it does not exist, silently
create_log_file_silently() {
    local file_path=$1
    if [ ! -f "$file_path" ]; then
        # Create file silently and suppress any error messages
        touch "$file_path" >/dev/null 2>&1
    fi
}

# Create or verify log files silently
create_log_file_silently "$LOG_FILE"
create_log_file_silently "$LOG_FILE_MONITOR"



# Function to generate a performance report
generate_report() {
    # Initialize sum and count variables
    total_cpu_usage=0
    total_mem_usage=0
    total_disk_usage=0
    total_rx=0
    total_tx=0
    count=0
    today_date=$(date '+%Y-%m-%d')

    # Extract CPU usage values and compute the total and count
    count=$(cat $LOG_FILE_MONITOR | grep Information | grep CPU | grep -n CPU | cut -d':' -f1 | tail -n 1 )
    total_cpu_usage=$(cat $LOG_FILE_MONITOR | grep Information  | grep CPU | grep -n CPU | cut -d':' -f5 | cut -d'%' -f1 |  cut -c2- | awk '{sum += $1} END {print sum}')
    total_mem_usage=$(cat $LOG_FILE_MONITOR  | grep Information | grep Mem | grep -n Mem | cut -d':' -f6 | cut -d'%' -f1 | cut -c2- | awk '{sum += $1} END {print sum}')
    total_disk_usage=$(cat $LOG_FILE_MONITOR  | grep Information | grep Disk | grep -n Disk | cut -d':' -f7 | cut -d'%' -f1 | cut -c2- | awk '{sum += $1} END {print sum}')
    
    total_rx=$(cat $LOG_FILE_MONITOR | grep Net | grep -n Net | cut -d':' -f8 | cut -d'%' -f1 | cut -c2- | cut -d' ' -f2 | cut -d'K' -f1 | awk '{sum += $1} END {print sum}')
    total_tx=$(cat system_logs/system_monitor.log | grep Net | grep -n Net | cut -d',' -f2 | cut -d' ' -f3 | cut -d'K' -f1 |  awk '{sum += $1} END {print sum}')
    
    
    # Calculate the average CPU usage if count is greater than zero
    if [ $count -gt 0 ]; then
        average_cpu_usage=$(echo "scale=2; $total_cpu_usage / $count" | bc)
        average_mem_usage=$(echo "scale=2; $total_mem_usage / $count" | bc)
        average_disk_usage=$(echo "scale=2; $total_disk_usage / $count" | bc)
        average_rx=$(echo "scale=2; $total_rx / $count" | bc)
        average_tx=$(echo "scale=2; $total_tx / $count" | bc)
        echo "================================================" > "$LOG_FILE"
        echo >> "$LOG_FILE"
        echo "System Performance Report for $(date '+%Y-%m-%d %H:%M:%S')..." >> "$LOG_FILE"
        echo "------------------------------------------------" >> "$LOG_FILE"
        echo >> "$LOG_FILE"
        echo "Summary of System Performance:" >> "$LOG_FILE"
        echo " - Average CPU Usage: $average_cpu_usage%" >> "$LOG_FILE"
        echo " - Average Memory Usage: $average_mem_usage%" >> "$LOG_FILE"
        echo " - Average Disk Usage: $average_disk_usage%" >> "$LOG_FILE"
        echo " - Average RX Rate: $average_rx KB/s" >> "$LOG_FILE"
        echo " - Average TX Rate: $average_tx KB/s" >> "$LOG_FILE"
    
    else
        echo "No data available to generate a report." >> "$LOG_FILE"
  
    fi
    
    echo "------------------------------------------------" >> "$LOG_FILE"
    echo >> "$LOG_FILE"
    
    # Summarize backups for today
    echo "Backup Summary for $today_date:" >> "$LOG_FILE"
    local successful_count=$(grep "Backup successful" "$LOG_FILE_MONITOR" | grep -c "$today_date")
    local issues_count=$(grep "Backup encountered issues" "$LOG_FILE_MONITOR" | grep -c "$today_date")
    echo " - Successful Backups: $successful_count" >> "$LOG_FILE"
    echo " - Backups with Issues: $issues_count" >> "$LOG_FILE"
        
    echo "------------------------------------------------" >> "$LOG_FILE"
    echo >> "$LOG_FILE"
    
    
    # Warning Summary

    # Filter warnings by today's date and count them
    local warning_count=$(grep "$today_date" "$LOG_FILE_MONITOR" | grep -c "Warning:")
    if [ "$warning_count" -gt 0 ]; then
       	 echo "Warnings for $today_date:" >> "$LOG_FILE"
       	 echo " - Number of Warnings: $warning_count" >> "$LOG_FILE"
    else
       	 echo "No warning data available for today." >> "$LOG_FILE"
    fi
  
      
    echo >> "$LOG_FILE"
    echo "================================================" >> "$LOG_FILE"
   
}

generate_report


