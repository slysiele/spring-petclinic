pipeline {
    agent {
        kubernetes {
            yaml '''
        apiVersion: v1
        kind: Pod
        metadata:
          labels:
            app: petclinic-builder
        spec:
          serviceAccountName: jenkins
          containers:
          - name: maven
            image: maven:3.9-eclipse-temurin-21
            command:
            - cat
            tty: true
            volumeMounts:
            - mountPath: "/root/.m2/repository"
              name: maven-cache
          - name: git
            image: bitnami/git:latest
            command:
            - cat
            tty: true
          - name: kaniko
            image: gcr.io/kaniko-project/executor:debug
            command: ["/busybox/cat"]
            tty: true
            volumeMounts:
            - name: docker-config
              mountPath: /kaniko/.docker
          - name: kubectl
            image: bitnami/kubectl:latest
            command:
            - cat
            tty: true
          volumes:
          - name: maven-cache
            persistentVolumeClaim:
              claimName: maven-cache
          - name: docker-config
            secret:
              secretName: docker-credentials
              items:
              - key: .dockerconfigjson
                path: config.json
      '''
        }
    }

    environment {
        DOCKER_USERNAME = "silvestor"
        APP_NAME = "petclinic"
        IMAGE_NAME = "${DOCKER_USERNAME}/${APP_NAME}"
        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout Code') {
            steps {
                container('git') {
                    echo '========== CHECKOUT CODE =========='
                    git url: 'https://github.com/slysiele/spring-petclinic',
                            branch: 'main'
                    sh 'ls -la'
                }
            }
        }

        stage('Build Application') {
            steps {
                container('maven') {
                    echo '========== BUILD APPLICATION =========='
                    sh 'mvn clean package -DskipTests -Denforcer.skip=true'
                    sh 'ls -lah target/*.jar'
                }
            }
        }

        stage('Run Tests') {
            steps {
                container('maven') {
                    echo '========== RUN UNIT TESTS =========='
                    sh 'mvn test'
                }
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                container('kaniko') {
                    echo '========== BUILD DOCKER IMAGE =========='
                    sh '''
                        /kaniko/executor \
                          --context=${WORKSPACE} \
                          --dockerfile=Dockerfile \
                          --destination=${IMAGE_NAME}:${IMAGE_TAG} \
                          --destination=${IMAGE_NAME}:latest \
                          --cache=true
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                container('kubectl') {
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
            echo "Docker Image: ${IMAGE_NAME}:${IMAGE_TAG}"
            echo "Application: http://<MASTER_IP>:30081"
        }
        failure {
            echo ' Pipeline failed! Check logs above'
        }
    }
}
