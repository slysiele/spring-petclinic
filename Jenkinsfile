pipeline {
    agent any

    environment {
        DOCKER_IMAGE_NAME = 'silvestor/petclinic'
        DOCKER_IMAGE_TAG = "${BUILD_NUMBER}"
        GITHUB_REPO = 'https://github.com/slysiele/spring-petclinic.git'
    }

    stages {
        stage('Checkout') {
            steps {
                echo '========== CHECKOUT CODE =========='
                cleanWs()
                git branch: 'main', url: "${GITHUB_REPO}"
                sh 'ls -la'
            }
        }

        stage('Build Application') {
            steps {
                echo '========== BUILD APPLICATION =========='
                sh './mvnw clean package -DskipTests -Denforcer.skip=true'
                sh 'ls -la target/'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo '========== BUILD DOCKER IMAGE =========='
                sh '''
                    docker build -t ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} .
                    docker tag ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} ${DOCKER_IMAGE_NAME}:latest
                    docker images | grep petclinic
                '''
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo '========== PUSH TO DOCKER HUB =========='
                withCredentials([usernamePassword(
                        credentialsId: 'docker-hub-creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        echo "${DOCKER_PASS}" | docker login -u "${DOCKER_USER}" --password-stdin
                        docker push ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}
                        docker push ${DOCKER_IMAGE_NAME}:latest
                        docker logout
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo '========== DEPLOY TO KUBERNETES =========='
                sh '''
                    # Create namespace if it doesn't exist
                    kubectl create namespace petclinic --dry-run=client -o yaml | kubectl apply -f -
                    
                    # Update deployment image tag
                    sed -i "s|image: silvestor/petclinic:.*|image: silvestor/petclinic:${DOCKER_IMAGE_TAG}|g" k8s/deployment.yaml
                    
                    # Apply manifests
                    kubectl apply -f k8s/deployment.yaml
                    kubectl apply -f k8s/service.yaml
                    
                    # Verify deployment
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
                    
                    echo "Service endpoints:"
                    kubectl get svc -n petclinic
                '''
            }
        }
    }

    post {
        success {
            echo ' Pipeline succeeded! Application deployed.'
        }
        failure {
            echo ' Pipeline failed! Check logs above.'
        }
    }
}
