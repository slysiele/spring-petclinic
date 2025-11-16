pipeline {
    agent any

    environment {
        DOCKER_USERNAME = "silvestor"
        APP_NAME = "petclinic"
        IMAGE_NAME = "${DOCKER_USERNAME}/${APP_NAME}"
        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout Code') {
            steps {
                echo '========== CHECKOUT CODE =========='
                sh 'rm -rf .git 2>/dev/null || true'
                git url: 'https://github.com/slysiele/spring-petclinic', branch: 'main'
                sh 'ls -la'
            }
        }

        stage('Build Application') {
            steps {
                echo '========== BUILD APPLICATION =========='
                sh './mvnw clean package -DskipTests -Denforcer.skip=true'
                sh 'ls -lah target/*.jar'
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                echo '========== BUILD DOCKER IMAGE =========='
                sh '''
                    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                    docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest
                    docker images | grep petclinic
                '''
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo '========== PUSH TO DOCKER HUB =========='
                withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        echo "${DOCKER_PASS}" | docker login -u "${DOCKER_USER}" --password-stdin
                        docker push ${IMAGE_NAME}:${IMAGE_TAG}
                        docker push ${IMAGE_NAME}:latest
                        docker logout
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo '========== DEPLOY TO KUBERNETES =========='
                sh '''
                    kubectl create namespace petclinic --dry-run=client -o yaml | kubectl apply -f -
                    kubectl apply -f k8s/deployment.yaml
                    kubectl apply -f k8s/service.yaml
                    kubectl get pods -n petclinic
                    kubectl get svc -n petclinic
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                echo '========== VERIFY DEPLOYMENT =========='
                sh '''
                    echo "Waiting for rollout..."
                    kubectl rollout status deployment/petclinic -n petclinic --timeout=5m
                    echo "Final pod status:"
                    kubectl get pods -n petclinic -o wide
                '''
            }
        }
    }

    post {
        success {
            echo ' Pipeline succeeded! Application deployed successfully'
            echo "Docker Image: ${IMAGE_NAME}:${IMAGE_TAG}"
            echo "Application: http://<MASTER_IP>:30081"
        }
        failure {
            echo ' Pipeline failed! Check logs above'
        }
    }
}
