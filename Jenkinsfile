pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'silvestor/petclinic'
        BUILD_TAG = "${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                echo '========== CHECKOUT CODE =========='
                cleanWs()
                git branch: 'main', url: 'https://github.com/slysiele/spring-petclinic.git'
                sh 'ls -la'
            }
        }

        stage('Build') {
            steps {
                echo '========== BUILD APPLICATION =========='
                sh './mvnw clean package -DskipTests -Denforcer.skip=true'
                sh 'ls -lah target/*.jar'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo '========== BUILD DOCKER IMAGE =========='
                sh '''
                    docker build -t ${DOCKER_IMAGE}:${BUILD_TAG} .
                    docker tag ${DOCKER_IMAGE}:${BUILD_TAG} ${DOCKER_IMAGE}:latest
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
                        docker push ${DOCKER_IMAGE}:${BUILD_TAG}
                        docker push ${DOCKER_IMAGE}:latest
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
                    echo "Final status:"
                    kubectl get pods -n petclinic -o wide
                '''
            }
        }
    }

    post {
        success {
            echo ' Pipeline succeeded! Application deployed successfully'
        }
        failure {
            echo ' Pipeline failed! Check logs above'
        }
    }
}
