pipeline {
    agent {
        kubernetes {
            namespace 'default'
            yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins: agent
spec:
  serviceAccountName: jenkins
  containers:
  - name: maven
    image: maven:3.9-eclipse-temurin-21
    command:
    - sleep
    args:
    - 99d
    volumeMounts:
    - name: maven-cache
      mountPath: /root/.m2
  - name: docker
    image: docker:24-dind
    securityContext:
      privileged: true
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run
  - name: kubectl
    image: bitnami/kubectl:latest
    command:
    - sleep
    args:
    - 99d
  volumes:
  - name: maven-cache
    emptyDir: {}
  - name: docker-sock
    emptyDir: {}
'''
        }
    }

    environment {
        DOCKER_HUB_REPO = 'silvestor/petclinic'
        DOCKER_CREDENTIALS_ID = 'docker-hub-creds'
        GIT_COMMIT_SHORT = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
        IMAGE_TAG = "${env.BUILD_NUMBER}-${GIT_COMMIT_SHORT}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    echo "Building commit: ${GIT_COMMIT_SHORT}"
                    echo "Image tag: ${IMAGE_TAG}"
                }
            }
        }

        stage('Build Application') {
            steps {
                container('maven') {
                    sh '''
                        echo "========== BUILD APPLICATION =========="
                        ./mvnw clean package -DskipTests -Denforcer.skip=true
                    '''
                }
            }
        }

        stage('Run Tests') {
            steps {
                container('maven') {
                    sh '''
                        echo "========== RUN UNIT TESTS =========="
                        ./mvnw test
                    '''
                }
            }
            post {
                always {
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('Static Analysis - SonarQube') {
            steps {
                container('maven') {
                    script {
                        echo "========== SONARQUBE ANALYSIS =========="
                        echo "SonarQube analysis would run here (optional)"
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                container('docker') {
                    sh '''
                        echo "========== BUILD DOCKER IMAGE =========="
                        dockerd &
                        sleep 10
                        docker build -t ${DOCKER_HUB_REPO}:${IMAGE_TAG} .
                        docker tag ${DOCKER_HUB_REPO}:${IMAGE_TAG} ${DOCKER_HUB_REPO}:latest
                        docker images | grep petclinic
                    '''
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                container('docker') {
                    echo '========== PUSH TO DOCKER HUB =========='
                    withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh '''
                            echo "${DOCKER_PASS}" | docker login -u "${DOCKER_USER}" --password-stdin
                            docker push ${DOCKER_HUB_REPO}:${IMAGE_TAG}
                            docker push ${DOCKER_HUB_REPO}:latest
                            docker logout
                        '''
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                container('kubectl') {
                    echo '========== DEPLOY TO KUBERNETES =========='
                    sh '''
                        kubectl create namespace petclinic --dry-run=client -o yaml | kubectl apply -f -
                        sed -i "s|image:.*|image: ${DOCKER_HUB_REPO}:${IMAGE_TAG}|g" k8s/deployment.yaml
                        kubectl apply -f k8s/deployment.yaml
                        kubectl apply -f k8s/service.yaml
                        kubectl get pods -n petclinic
                        kubectl get svc -n petclinic
                    '''
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                container('kubectl') {
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
    }

    post {
        success {
            echo ' Pipeline succeeded! Application deployed successfully'
            echo "Docker Image: ${DOCKER_HUB_REPO}:${IMAGE_TAG}"
            echo "Application: http://<MASTER_IP>:30081"
        }
        failure {
            echo ' Pipeline failed! Check logs above'
        }
    }
}
