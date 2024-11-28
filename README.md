# Shell Scripting Project: Linux System Automation Tools

Welcome to the Shell Scripting Project repository! This collection of shell scripts is designed to simplify and automate various Linux system administration tasks. Each script addresses a specific need, helping you manage users, maintain Docker environments, and back up Jenkins data with minimal effort.

---

## 📁 **Scripts Included**

### **1. Create Users on Linux (`createusersonlinux.sh`)**
Effortlessly manage users on a Linux system by automating account creation, group assignment, and secure password generation.

#### **Features:**
- Reads user and group data from a structured input file.
- Creates users and groups as specified.
- Sets up home directories with correct permissions.
- Generates secure random passwords for each user.
- Logs all actions for auditing and troubleshooting.
- Stores passwords securely in `/var/secure/user_passwords.csv`.

#### **Usage:**
1. Ensure root privileges:
   ```bash
   sudo ./createusersonlinux.sh <input_file>
