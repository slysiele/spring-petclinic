pipeline {
    agent any

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

        stage('Build') {
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

        stage('Install kubectl') {
            steps {
                echo '========== INSTALL KUBECTL =========='
                sh '''
                    echo "Installing kubectl..."
                    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                    chmod +x kubectl
                    mkdir -p $HOME/bin
                    mv kubectl $HOME/bin/
                    export PATH=$HOME/bin:$PATH
                    $HOME/bin/kubectl version --client
                '''
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo '========== DEPLOY TO KUBERNETES =========='
                sh '''
                    export PATH=$HOME/bin:$PATH
                    cd /tmp/spring-petclinic
            
                    JAR_FILE=$(ls target/spring-petclinic*.jar | head -1)
                    echo "JAR file: $JAR_FILE"
                    
                    $HOME/bin/kubectl create namespace petclinic --dry-run=client -o yaml | $HOME/bin/kubectl apply -f -
                    $HOME/bin/kubectl create configmap petclinic-app --from-file=$JAR_FILE \
                      -n petclinic --dry-run=client -o yaml | $HOME/bin/kubectl apply -f -
            
                    $HOME/bin/kubectl apply -f - <<'K8S'
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
        image: eclipse-temurin:21-jdk-alpine
        command:
          - sh
          - -c
          - "java -jar /app/*.jar"
        ports:
        - containerPort: 8080
        volumeMounts:
        - name: app-jar
          mountPath: /app
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
      volumes:
      - name: app-jar
        configMap:
          name: petclinic-app
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
K8S
        
                    $HOME/bin/kubectl get pods -n petclinic
                    $HOME/bin/kubectl get svc -n petclinic
                '''
            }
        }

        stage('Verify') {
            steps {
                echo '========== VERIFY DEPLOYMENT =========='
                sh '''
                    export PATH=$HOME/bin:$PATH
                    
                    echo "Pods:"
                    $HOME/bin/kubectl get pods -n petclinic
                    
                    echo "Services:"
                    $HOME/bin/kubectl get svc -n petclinic
                    
                    echo "Waiting for pods to be ready..."
                    $HOME/bin/kubectl wait --for=condition=ready pod -l app=petclinic -n petclinic --timeout=300s || true
                    
                    echo "Final status:"
                    $HOME/bin/kubectl get pods -n petclinic -o wide
                '''
            }
        }
    }

    post {
        success {
            sh 'echo " SUCCESS! Access app at browser"'
        }
        failure {
            sh 'echo " FAILED - Check logs above"'
        }
    }
}
