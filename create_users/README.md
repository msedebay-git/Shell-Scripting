
# Shell scripting project to create users

Managing users on a Linux system can be a daunting task, especially in environments where you need to create multiple users, assign them to specific groups, and ensure they have secure passwords. 

## The problem statement

Your company has hired many new developers, and you need to automate the creation of user accounts and passwords for each of them on a given server.

As a DevOps engineer, write a Bash script that reads a text file containing the employees’ usernames and group names, where each line is formatted as username; groups.

The text file can also specify multiple groups for the user, formatted as username; group1, group2.

The script should create users and groups as specified, set up home directories with appropriate permissions and ownership, and generate random user passwords.

Additionally, store the generated passwords securely in /var/secure/user_passwords.csv, and log all actions to /var/log/user_management.log.

How do you automate this workflow with Bash scripting?

## Setting up the project
Before diving head first into creating the script itself, let's define what it needs to automate.


## 1. Ensuring root privileges
```
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root or sudo privileges "
  exit 1
fi
```

## 2. Check if user list file path is provided as argument
```
if [ $# -ne 1 ]; then
    echo "Usage: $0 <input_file>"
    exit 1
fi

# Check if user list file exists
if [ ! -f "$INPUT_FILE" ]; then
  echo "User list file '$INPUT_FILE' not found. Please check the path."
  exit 1
fi
```

## 3. Create necessary variables
```
INPUT_FILE="$1"
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"
```

## 4. Create the log and password files
```
if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
    chmod 0600 "$LOG_FILE"
fi

# Create the password file if it doesn't exist
if [ ! -f "$PASSWORD_FILE" ]; then
    mkdir -p /var/secure
    touch "$PASSWORD_FILE"
    chmod 0600 "$PASSWORD_FILE"
fi
```
## 5. Creating the users and groups
```
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

done < "$INPUT_FILE"
```

## 6. Generate Psuedo password, assign to user and store the password
```
generate_password() {
    openssl rand -base64 12
}

    # Create and set a user password
    password=$(generate_password)
    log_message "Generated password for $username"

    # Set user password
    echo "$username:$password" | chpasswd

    # Save user and password to a file
    echo "$username,$password" >> $PASSWORD_FILE
```

## 7. Running the Script
```
 $ chmod +x create_users.sh
 $  sudo ./create_users.sh <input_file>
```


