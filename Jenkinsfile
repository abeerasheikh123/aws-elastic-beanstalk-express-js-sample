pipeline {
    agent any

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

        stage('Install Dependencies') {
            steps {
                script {
                    docker.image('node:16').inside {
                        sh 'npm install --save'
                        // skip test if not defined
                        sh '''
                        if npm run | grep -q "test"; then
                          npm test
                        else
                          echo "No npm test script defined; skipping tests."
                        fi
                        '''
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${DOCKER_HUB_REPO}:latest ."
            }
        }

        stage('Image Vulnerability Scan (Trivy)') {
            steps {
                sh '''
                docker run --rm \
                  -v /var/run/docker.sock:/var/run/docker.sock \
                  aquasec/trivy:latest image --exit-code 0 --severity MEDIUM,HIGH,CRITICAL ${DOCKER_HUB_REPO}:latest
                '''
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
    }
}
