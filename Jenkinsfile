pipeline {
    agent any   // Default agent (has Docker CLI)

    environment {
        DOCKER_HUB_REPO = "abeerasheikh/aws-sample-nodejs-app"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo "Checked out ${env.GIT_COMMIT}"
            }
        }

        stage('Install Dependencies & Test (Node 16)') {
            agent {
                docker {
                    image 'node:16'
                }
            }
            steps {
                sh 'npm install --save'
                sh '''
                if npm run | grep -q "test"; then
                  npm test
                else
                  echo "No npm test script defined; skipping tests."
                fi
                '''
            }
        }

        stage('Dependency Vulnerability Scan (Snyk)') {
            agent {
                docker {
                    image 'node:16'
                }
            }
            steps {
                sh 'npm install -g snyk'
                withCredentials([string(credentialsId: 'snyk-token', variable: 'SNYK_TOKEN')]) {
                    sh 'snyk auth $SNYK_TOKEN'
                    // Fail the build if high/critical vulnerabilities are detected
                    sh 'snyk test --severity-threshold=high'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${DOCKER_HUB_REPO}:latest ."
            }
        }

        stage('Push to DockerHub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                    echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                    docker push ${DOCKER_HUB_REPO}:latest
                    '''
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline finished. Check logs for details."
        }
        failure {
            echo "Build failed — check Snyk or earlier stage logs."
        }
    }
}
