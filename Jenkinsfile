pipeline {
    agent any
    stages {
        stage('Check Docker') {
            steps {
                sh 'docker --version'
            }
        }
        stage('Build') {
            steps {
                sh 'docker pull node:16'
            }
        }
    }
}
