pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "abeerasheikh/my-node-app" // change if needed
    }

    stages {
        stage('Install Dependencies') {
            steps {
                // Run npm install inside a Node 16 container
                sh 'docker run --rm -v $PWD:/app -w /app node:16 npm install --save'
            }
        }

        stage('Run Tests') {
            steps {
                // Run tests inside Node 16 container
                sh 'docker run --rm -v $PWD:/app -w /app node:16 npm test'
            }
        }

        stage('Security Scan with Snyk') {
            steps {
                withCredentials([string(credentialsId: '6407896b-2168-48c1-8346-53ccc219e856', variable: 'SNYK_TOKEN')]) {
                    // Run Snyk scan inside Node 16 container
                    sh '''
                        docker run --rm -v $PWD:/app -w /app node:16 sh -c "
                        npm install -g snyk && \
                        snyk auth $SNYK_TOKEN && \
                        snyk test --severity-threshold=high || exit 1"
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                // Build Docker image using DinD
                sh 'docker build -t $DOCKER_IMAGE:$BUILD_NUMBER .'
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'ec2f6674-297e-4506-a79b-5a8ba437edfd', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push $DOCKER_IMAGE:$BUILD_NUMBER
                    '''
                }
            }
        }
    }
}
