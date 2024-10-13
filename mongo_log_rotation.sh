#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Define log file for the script itself
script_log_file="/var/log/mongodb_log_rotation.log"
echo "[$(date)] Starting MongoDB log rotation." >> "$script_log_file"

# Check if mongosh is installed
if ! command -v mongosh &> /dev/null; then
    echo "mongosh could not be found. Please install it before running this script."
    echo "[$(date)] mongosh not installed. Exiting." >> "$script_log_file"
    exit 1
fi

# Define MongoDB connection details (improve security with environment variables)
MONGODB_USERNAME="${MONGODB_USERNAME:-}"
MONGODB_PASSWORD="${MONGODB_PASSWORD:-}"

if [[ -z "$MONGODB_USERNAME" || -z "$MONGODB_PASSWORD" ]]; then
    echo "MongoDB username or password is not set. Please set the MONGODB_USERNAME and MONGODB_PASSWORD environment variables."
    echo "[$(date)] MongoDB username/password not set. Exiting." >> "$script_log_file"
    exit 1
fi

# Define search criteria for old log files
log_dir="/var/log/mongodb/"
log_prefix="mongod.log"
max_file_age=5 # Files older than 5 days will be archived
archive_dir="/var/log/mongodb/archive/"

# Log directory existence and permission checks
if [ ! -d "$log_dir" ]; then
    echo "Log directory $log_dir does not exist. Exiting."
    echo "[$(date)] Log directory $log_dir does not exist. Exiting." >> "$script_log_file"
    exit 1
fi

if [ ! -w "$log_dir" ]; then
    echo "No write permission for $log_dir. Exiting."
    echo "[$(date)] No write permission for $log_dir. Exiting." >> "$script_log_file"
    exit 1
fi

# Create archive directory if it does not exist
if [ ! -d "$archive_dir" ]; then
    mkdir -p "$archive_dir"
fi

# Trigger MongoDB log rotation
mongo_command="db.adminCommand({ logRotate: 1 })"
if ! mongosh_output=$(mongosh --eval "$mongo_command" -u "$MONGODB_USERNAME" -p "$MONGODB_PASSWORD" 2>&1); then
    echo "Failed to rotate MongoDB logs. Error: $mongosh_output"
    echo "[$(date)] Failed to rotate MongoDB logs. Error: $mongosh_output" >> "$script_log_file"
    exit 1
fi

echo "[$(date)] Log rotation command executed successfully." >> "$script_log_file"

# Timeout flexibility: Check if log rotation created a new log file
rotate_check_count=0
max_rotate_check=5
while [ $rotate_check_count -lt $max_rotate_check ]; do
    if ls "$log_dir" | grep -q "${log_prefix}"; then
        echo "[$(date)] Log rotation completed successfully." >> "$script_log_file"
        break
    fi
    rotate_check_count=$((rotate_check_count + 1))
    echo "[$(date)] Waiting for log rotation to complete... (Attempt $rotate_check_count)" >> "$script_log_file"
    sleep 30
done

if [ $rotate_check_count -eq $max_rotate_check ]; then
    echo "Log rotation did not complete within expected time."
    echo "[$(date)] Log rotation timeout." >> "$script_log_file"
    exit 1
fi

# Find and archive old log files
echo "[$(date)] Archiving old log files older than $max_file_age days." >> "$script_log_file"
find "$log_dir" -name "${log_prefix}*" -mtime +"$max_file_age" -exec gzip -c {} > "$archive_dir"/{}.gz \; -exec rm -rf {} \;

if [ $? -eq 0 ]; then
    echo "[$(date)] Old log files archived and cleaned up successfully." >> "$script_log_file"
else
    echo "[$(date)] Error occurred during archiving or cleanup of old log files." >> "$script_log_file"
    exit 1
fi

echo "[$(date)] MongoDB log rotation and cleanup process completed successfully." >> "$script_log_file"
