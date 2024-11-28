#!/bin/bash

#---------------------------------------------#
# Author: M Sedebay 
# Contact email: moham361986@gmail.com
#---------------------------------------------#

# Define the file paths for the logfile, and the password file
INPUT_FILE="$1"
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"

# Ensure script is run with root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root or sudo privileges "
  exit 1
fi

# Check if user list file path is provided as argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 <input_file>"
    exit 1
fi

# Check if user list file exists
if [ ! -f "$INPUT_FILE" ]; then
  echo "User list file '$INPUT_FILE' not found. Please check the path."
  exit 1
fi

# Function to generate logs
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

# Create the log file if it doesn't exist
if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
    chmod 0600 "$LOG_FILE"
    log_message "Log file created: $LOG_FILE"
fi

# Create the password file if it doesn't exist
if [ ! -f "$PASSWORD_FILE" ]; then
    mkdir -p /var/secure
    touch "$PASSWORD_FILE"
    chmod 0600 "$PASSWORD_FILE"
    log_message "Password file created: $PASSWORD_FILE"
fi

# Function to generate a random Psuedo password
generate_password() {
    openssl rand -base64 12
}

# Read the input file line by line and save them into variables
while IFS=';' read -r username groups || [ -n "$username" ]; do
    username=$(echo "$username" | xargs)
    groups=$(echo "$groups" | xargs)

    # Check if the personal group exists, create one if it doesn't
    if ! getent group "$username" &>/dev/null; then
        echo "Group $username does not exist, adding it now"
        groupadd "$username"
        log_message "Created personal group $username"
    fi

    # Check if the user exists
    if id -u "$username" &>/dev/null; then
        echo "User $username exists"
        log_message "User $username already exists"
    else
        # Create a new user with the created group if the user does not exist
        useradd -m -g $username -s /bin/bash "$username"
        log_message "Created a new user $username"
    fi

    # Check if the groups were specified
    if [ -n "$groups" ]; then
        # Read through the groups saved in the groups variable created earlier and split each group by ','
        IFS=',' read -r -a group_array <<< "$groups"

        # Loop through the groups
        for group in "${group_array[@]}"; do
            # Remove the trailing and leading whitespaces and save each group to the group variable
            group=$(echo "$group" | xargs) # Remove leading/trailing whitespace

            # Check if the group already exists
            if ! getent group "$group" &>/dev/null; then
                # If the group does not exist, create a new group
                groupadd "$group"
                log_message "Created group $group."
            fi

            # Add the user to each group
            usermod -aG "$group" "$username"
            log_message "Added user $username to group $group."
        done
    fi

    # Create and set a user password
    password=$(generate_password)
    echo "$username:$password" | chpasswd
    # Save user and password to a file
    echo "$username,$password" >> $PASSWORD_FILE

done < "$INPUT_FILE"

log_message "User created successfully"
echo "Users have been created and added to their groups successfully"
