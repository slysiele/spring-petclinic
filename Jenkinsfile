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

        stage('Build & Push Docker Image with Kaniko') {
            steps {
                echo '========== BUILD & PUSH IMAGE =========='

                container('kaniko') {
                    withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {

                        sh '''
                        echo "{\"auths\":{\"https://index.docker.io/v1/\":{\"username\":\"$DOCKER_USER\",\"password\":\"$DOCKER_PASS\"}}}" \
                        > /kaniko/.docker/config.json

                        /kaniko/executor \
                          --dockerfile=Dockerfile \
                          --context=`pwd` \
                          --destination=${IMAGE_NAME}:${IMAGE_TAG} \
                          --destination=${IMAGE_NAME}:latest
                        '''
                    }
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
            echo "Application available on NodePort service."
        }
        failure {
            echo ' Pipeline failed! Check logs above'
        }
    }
}
