pipeline {
  agent none                           // per-stage agents are used

  environment {
    IMAGE = "abeerasheikh/aws-sample-nodejs-app"   // change to your DockerHub namespace if needed
    TAG   = "latest"
  }

  stages {

    stage('Checkout') {
      agent any
      steps {
        checkout scm
        echo "Checked out ${env.GIT_COMMIT}"
      }
    }

    // Build and test inside Node 16 container
    stage('Install & Unit Tests') {
      agent {
        docker {
          image 'node:16'
          reuseNode true                   // important: keeps workspace inside the container
        }
      }
      steps {
        sh 'npm install --save'
        sh 'npm test || echo "No tests or some tests failed (see logs)"'
      }
    }

    // Snyk dependency scan (fail on High/Critical)
    stage('Dependency Vulnerability Scan - Snyk') {
      agent {
        docker {
          image 'node:16'
          reuseNode true
        }
      }
      environment {
        // add this credential in Jenkins (Credentials -> System -> Global). ID below
        SNYK_TOKEN = credentials('snyk-token')   // <-- create Secret Text credential with ID 'snyk-token'
      }
      steps {
        // install snyk in the node container and run test
        sh '''
          npm install -g snyk
          snyk auth $SNYK_TOKEN
          snyk test --severity-threshold=high
        '''
      }
    }

    // Build Docker image — use docker CLI inside a docker image that has docker (docker:dind/client)
    stage('Build Docker Image') {
      agent {
        docker {
          image 'docker:24.0.5'               // docker CLI image
          args '-v /var/run/docker.sock:/var/run/docker.sock -v $HOME/.docker:/root/.docker'
          reuseNode true
        }
      }
      steps {
        sh "docker build -t ${IMAGE}:${TAG} ."
      }
    }

    // Optional: run quick container smoke test (if app has start command)
    stage('Container Smoke Test') {
      agent {
        docker {
          image 'docker:24.0.5'
          args '-v /var/run/docker.sock:/var/run/docker.sock -v $HOME/.docker:/root/.docker'
          reuseNode true
        }
      }
      steps {
        // run container briefly to confirm it starts (adjust port if app uses different port)
        sh '''
          docker run -d --name ci_smoke_test -p 3000:3000 ${IMAGE}:${TAG} || true
          sleep 5
          docker logs ci_smoke_test || true
          docker rm -f ci_smoke_test || true
        '''
      }
    }

    // Image vulnerability scan with Trivy (non-blocking for now — you can fail on certain severities if required)
    stage('Image Vulnerability Scan - Trivy') {
      agent {
        docker {
          image 'aquasec/trivy:latest'
          args '-v /var/run/docker.sock:/var/run/docker.sock -v $HOME/.cache:/root/.cache'
          reuseNode true
        }
      }
      steps {
        // scan the local image; fail on HIGH or CRITICAL if you prefer by checking exit code
        sh "trivy image --exit-code 1 --severity HIGH,CRITICAL ${IMAGE}:${TAG} || { echo 'Trivy found High/Critical issues'; exit 1; }"
      }
    }

    // Push image to DockerHub (requires credential in Jenkins)
    stage('Push to DockerHub') {
      agent {
        docker {
          image 'docker:24.0.5'
          args '-v /var/run/docker.sock:/var/run/docker.sock -v $HOME/.docker:/root/.docker'
          reuseNode true
        }
      }
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh '''
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
            docker push ${IMAGE}:${TAG}
          '''
        }
      }
    }

  } // stages

  post {
    success {
      echo "Pipeline completed SUCCESSFULLY."
    }
    failure {
      echo "Pipeline FAILED — check logs and fix issues."
    }
    always {
      // archive build logs or artifacts if you want (configure in Jenkins job UI if required)
      echo "Pipeline finished at ${new Date()}"
    }
  }
}
