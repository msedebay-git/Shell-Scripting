#!/bin/bash

#---------------------------------------------#
# Author: M Sedebay 
# Contact email: moham361986@gmail.com
#---------------------------------------------#


# Ensure script is run with root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root or sudo privileges "
  exit 1
fi

# Define variables
JENKINS_HOME="$1"
AWS_ACCESS_KEY_ID="$2"
AWS_SECRET_ACCESS_KEY="$3"
DEST_FILE="/tmp/test"
TMP_DIR="/tmp"
ARC_NAME="jenkins-backup"
ARC_DIR="${TMP_DIR}/${ARC_NAME}"
TMP_TAR_NAME="${TMP_DIR}/jenkins-archive.tar.gz"
FINAL_TAR_NAME=jenkins-archive-$(date -d "today" +"%Y%m%d%H%M").tar.gz
LOG_FILE="/var/log/jenkins_backup.log"

# Function to generate logs
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

# Function to upload backup tar to S3 bucket
copyto_s3() {
    AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY aws s3 cp ${FINAL_TAR_NAME} s3://wezvatech-jenkins-backup-9739110917/
    exitcode=$?
    if [ "$exitcode" != "1" ] && [ "$exitcode" != "0" ]; then
      exit $exitcode
    fi
    log_message "Copied Jenkins backup tar to S3 bucket .."
}

# Function to take backup
backup_jobs() {
   run_in_path="$1"

  if [ -d "${run_in_path}" ]; then
    cd "${run_in_path}"

    find . -maxdepth 1 -type d | while read job_name; do
      [ "${job_name}" = "." ] && continue
      [ "${job_name}" = ".." ] && continue
      [ -d "${JENKINS_HOME}/jobs/${job_name}" ] && mkdir -p "${ARC_DIR}/jobs/${job_name}/"
      find "${JENKINS_HOME}/jobs/${job_name}/" -maxdepth 1  \( -name "builds" -o -name "*.xml" -o -name "nextBuildNumber" \) -print0 | xargs -0 -I {} cp -R {} "${ARC_DIR}/jobs/${job_name}/"
    done

    cd -
  fi
}

# main function call
  if [ -z "${JENKINS_HOME}" ] ; then
    echo "usage: $(basename $0) /path/to/jenkins_home"
    exit 1
  fi

  rm -rf "${ARC_DIR}" "{$TMP_TAR_NAME}"
  for plugin in plugins jobs users secrets nodes; do
    mkdir -p "${ARC_DIR}/${plugin}"
    log_message "Backup folder for tar created .."
  done

  cp "${JENKINS_HOME}/"*.xml "${ARC_DIR}"

  # Copy only the plugin files
  cp "${JENKINS_HOME}/plugins/"*.[hj]pi "${ARC_DIR}/plugins"
  log_message "Plugins dir copied .."

  # Copy the users
  if [ "$(ls -A ${JENKINS_HOME}/users/)" ]; then
    cp -R "${JENKINS_HOME}/users/"* "${ARC_DIR}/users"
    log_message "Users dir copied .."
  fi

  # Copy secrets
  if [ "$(ls -A ${JENKINS_HOME}/secrets/)" ] ; then
    cp -R "${JENKINS_HOME}/secrets/"* "${ARC_DIR}/secrets"
    log_message "Secrets dir copied .."
  fi

  # Copy Slave nodes
  if [ "$(ls -A ${JENKINS_HOME}/nodes/)" ] ; then
    cp -R "${JENKINS_HOME}/nodes/"* "${ARC_DIR}/nodes"
    log_message "Nodes dir copied .."
  fi

  # Recursively copy all the jobs
  if [ "$(ls -A ${JENKINS_HOME}/jobs/)" ] ; then
    backup_jobs ${JENKINS_HOME}/jobs/
    log_message "Jobs dir copied .."
  fi

  # Create archive
  cd "${TMP_DIR}"
  tar -czvf "${TMP_TAR_NAME}" "${ARC_NAME}/"*
  log_message "Tar file created .."
  cd -

  cp "${TMP_TAR_NAME}" ${FINAL_TAR_NAME}
  log_message "Tar file renamed with timestamp .."
  rm -rf "${ARC_DIR}"

  # Copy the tar to S3
  copyto_s3
  echo "Successfully backedup Jenkins home dir ..."

  exit 0