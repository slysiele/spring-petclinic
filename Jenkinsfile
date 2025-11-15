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
                sh '''
                    cd /tmp
                    rm -rf spring-petclinic 2>/dev/null || true
                    git clone https://github.com/slysiele/spring-petclinic.git
                    cd spring-petclinic
                    ls -la
                '''
            }
        }

        stage('Build Application') {
            steps {
                echo '========== BUILD APPLICATION =========='
                sh '''
                    cd /tmp/spring-petclinic
                    ./mvnw clean package -DskipTests -Denforcer.skip=true
                    echo "JAR file created:"
                    ls -lah target/*.jar
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                echo '========== BUILD DOCKER IMAGE =========='
                sh '''
                    cd /tmp/spring-petclinic
                    
                    # Build the Docker image using host docker
                    docker build -t ${DOCKER_IMAGE}:${BUILD_TAG} .
                    docker tag ${DOCKER_IMAGE}:${BUILD_TAG} ${DOCKER_IMAGE}:latest
                    
                    # List images
                    docker images | grep petclinic
                '''
            }
        }

        stage('Install kubectl') {
            steps {
                echo '========== INSTALL KUBECTL =========='
                sh '''
                    if ! command -v kubectl &> /dev/null; then
                        echo "Installing kubectl..."
                        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                        chmod +x kubectl
                        mkdir -p $HOME/bin
                        mv kubectl $HOME/bin/
                    fi
                    
                    $HOME/bin/kubectl version --client
                '''
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo '========== DEPLOY TO KUBERNETES =========='
                sh '''
                    export PATH=$HOME/bin:$PATH
                    
                    # Create namespace
                    kubectl create namespace petclinic --dry-run=client -o yaml | kubectl apply -f -
                    
                    # Deploy using the Docker image
                    kubectl apply -f - <<'DEPLOY'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: petclinic
  namespace: petclinic
spec:
  replicas: 2
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: petclinic
  template:
    metadata:
      labels:
        app: petclinic
    spec:
      containers:
      - name: petclinic
        image: silvestor/petclinic:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
        livenessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 60
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: petclinic
  namespace: petclinic
spec:
  type: NodePort
  selector:
    app: petclinic
  ports:
  - port: 8080
    targetPort: 8080
    nodePort: 30081
DEPLOY
        
                    kubectl get pods -n petclinic
                    kubectl get svc -n petclinic
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                echo '========== VERIFY DEPLOYMENT =========='
                sh '''
                    export PATH=$HOME/bin:$PATH
                    
                    echo "Waiting for pods to be ready (this may take 2-3 minutes)..."
                    kubectl wait --for=condition=ready pod -l app=petclinic -n petclinic --timeout=300s || true
                    
                    echo "Final status:"
                    kubectl get pods -n petclinic -o wide
                    kubectl get svc -n petclinic
                '''
            }
        }
    }

    post {
        success {
            sh 'echo " SUCCESS! Access app on browser"'
        }
        failure {
            sh 'echo " FAILED - Check logs above"'
        }
    }
}
