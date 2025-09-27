pipeline {
  agent none

  environment {
    IMAGE = "abeerasheikh/aws-sample-nodejs-app"   // change to your DockerHub repo if needed
    TAG   = "latest"
    // DO NOT store secrets here. Use Jenkins Credentials
  }

  stages {
    stage('Checkout') {
      agent any
      steps {
        checkout scm
        echo "Checked out ${env.GIT_COMMIT}"
      }
    }

    stage('Install Dependencies & (optional) Tests') {
      agent {
        docker {
          image 'node:16'
          reuseNode true
        }
      }
      steps {
        sh 'npm install --save'
        // run tests if they exist; DO NOT fail pipeline if test script missing
        sh '''
          if npm run | grep -q "test"; then
            echo "Running npm test..."
            npm test || { echo "Unit tests failed (see logs)"; exit 1; }
          else
            echo "No npm test script defined; skipping tests."
          fi
        '''
      }
    }

    stage('Dependency Vulnerability Scan - OWASP Dependency-Check') {
      agent any
      steps {
        sh '''
          echo "Running OWASP Dependency-Check (docker image)..."
          # run dependency-check scanning the workspace, output into ./dependency-check-reports
          mkdir -p dependency-check-reports
          docker run --rm -v "$PWD":/src --workdir /src owasp/dependency-check:8.2.1 \
            --project "aws-sample-nodejs" --scan /src --out /src/dependency-check-reports || true

          # Check reports for HIGH or CRITICAL findings (XML/JSON/HTML may be present).
          # We'll search the generated files for HIGH or CRITICAL keywords.
          if grep -R -iE "HIGH|CRITICAL" dependency-check-reports/* >/dev/null 2>&1; then
            echo "Dependency-Check: HIGH or CRITICAL vulnerabilities detected!"
            # Print a short excerpt for logs
            grep -R -nE "HIGH|CRITICAL" dependency-check-reports/* | head -n 50 || true
            exit 1
          else
            echo "Dependency-Check: no HIGH/CRITICAL findings."
          fi
        '''
      }
    }

    stage('Build Docker Image') {
      agent any
      steps {
        // Use the Jenkins docker CLI (configured with DOCKER_HOST -> DinD)
        sh "docker build -t ${IMAGE}:${TAG} ."
      }
    }

    stage('Image Vulnerability Scan - Trivy (fail on HIGH/CRITICAL)') {
      agent any
      steps {
        sh '''
          echo "Scanning image with Trivy..."
          docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --exit-code 1 --severity HIGH,CRITICAL ${IMAGE}:${TAG} || { echo "Trivy: Found HIGH/CRITICAL issues"; exit 1; }
          echo "Trivy: No HIGH/CRITICAL issues found."
        '''
      }
    }

    stage('Push to DockerHub') {
      agent any
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
      echo "Pipeline SUCCESS: ${env.BUILD_URL}"
    }
    failure {
      echo "Pipeline FAILED: ${env.BUILD_URL}"
    }
    always {
      // Archive reports and artifacts for submission (useful for Task 4)
      archiveArtifacts artifacts: 'dependency-check-reports/**', allowEmptyArchive: true
      echo "Pipeline finished at ${new Date()}"
    }
  }
}
