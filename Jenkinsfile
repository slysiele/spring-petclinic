pipeline {

    agent {
        kubernetes {
            label 'docker-build'
        }
    }

    environment {
        DOCKER_IMAGE_NAME = 'silvestor/petclinic'
        DOCKER_IMAGE_TAG = "${BUILD_NUMBER}"
        GITHUB_REPO = 'https://github.com/slysiele/spring-petclinic.git'
    }

    stages {

        stage('Checkout') {
            steps {
                echo '========== CHECKOUT =========='
                git branch: 'main', url: "${GITHUB_REPO}"
            }
        }

        stage('Build JAR') {
            steps {
                echo '========== MAVEN BUILD =========='
                sh './mvnw clean package -DskipTests -Denforcer.skip=true'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo '========== DOCKER BUILD =========='
                sh """
            docker build -t ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} .
            docker tag ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} ${DOCKER_IMAGE_NAME}:latest
        """
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo '========== DOCKER PUSH =========='
                withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh """
              echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
              docker push ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}
              docker push ${DOCKER_IMAGE_NAME}:latest
          """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo '========== K8S DEPLOY =========='
                sh """
          kubectl create namespace petclinic --dry-run=client -o yaml | kubectl apply -f -
          sed -i "s|silvestor/petclinic:.*|silvestor/petclinic:${DOCKER_IMAGE_TAG}|g" k8s/deployment.yaml
          kubectl apply -f k8s/deployment.yaml
          kubectl apply -f k8s/service.yaml
          kubectl rollout status deployment/petclinic -n petclinic --timeout=5m
        """
            }
        }
    }

    post {
        success { echo 'Pipeline Completed Successfully!' }
        failure { echo 'Pipeline Failed!' }
    }
}
