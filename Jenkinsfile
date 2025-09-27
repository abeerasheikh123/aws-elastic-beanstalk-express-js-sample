pipeline {
    agent {
        docker { image 'node:16' }
    }

    environment {
        DOCKER_REGISTRY = 'your-dockerhub-username'
        IMAGE_NAME = 'node-app'
    }

    stages {
        stage('Install Dependencies') {
            steps {
                sh 'npm install --save'
            }
        }

        stage('Run Tests') {
            steps {
                sh 'npm test'
            }
        }

        stage('Security Scan') {
            steps {
                withCredentials([string(credentialsId: 'SNYK_TOKEN_ID', variable: 'SNYK_TOKEN')]) {
                    sh '''
                        npm install -g snyk
                        snyk auth $SNYK_TOKEN
                        snyk test --severity-threshold=high || exit 1
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t $DOCKER_REGISTRY/$IMAGE_NAME:$BUILD_NUMBER .'
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'DOCKERHUB_CREDS', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push $DOCKER_REGISTRY/$IMAGE_NAME:$BUILD_NUMBER
                    '''
                }
            }
        }
    }
}
