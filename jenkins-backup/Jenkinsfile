pipeline {
agent any

// Ensure environment variables are set as secret text type //
environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
}
stages{
  stage('Run Backup Script'){
    steps {
          sh "chmod +x jenkins_backup.sh && sudo ./jenkins_backup.sh /var/lib/jenkins $AWS_ACCESS_KEY_ID $AWS_SECRET_ACCESS_KEY"
        }
    }
  }
}
