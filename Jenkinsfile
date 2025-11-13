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

        stage('Deploy to Kubernetes') {
            steps {
                echo '========== DEPLOY TO KUBERNETES =========='
                sh '''
                    cd /tmp/spring-petclinic
                    
                    # Create namespace
                    kubectl create namespace petclinic --dry-run=client -o yaml | kubectl apply -f -
                    
                    # Copy JAR to a shared location
                    JAR_FILE=$(ls target/spring-petclinic*.jar | head -1)
                    echo "JAR file: $JAR_FILE"
                    
                    # Create ConfigMap with JAR
                    kubectl create configmap petclinic-app --from-file=$JAR_FILE \
                      -n petclinic --dry-run=client -o yaml | kubectl apply -f -
                    
                    # Deploy
                    kubectl apply -f - <<'K8S'
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
          - "ls /app && java -jar /app/*.jar"
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
          failureThreshold: 3
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
          defaultMode: 0755
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
    protocol: TCP
K8S

                    echo "Deployment created"
                '''
            }
        }

        stage('Verify') {
            steps {
                echo '========== VERIFY DEPLOYMENT =========='
                sh '''
                    echo "Pods:"
                    kubectl get pods -n petclinic
                    
                    echo "Services:"
                    kubectl get svc -n petclinic
                    
                    echo "Waiting for pods to be ready..."
                    kubectl wait --for=condition=ready pod -l app=petclinic -n petclinic --timeout=300s || true
                    
                    echo "Final status:"
                    kubectl get pods -n petclinic -o wide
                '''
            }
        }
    }

    post {
        success {
            sh 'echo "✅ SUCCESS! Access app at http://10.0.2.15:30081"'
        }
        failure {
            sh 'echo "❌ FAILED - Check logs above"'
        }
    }
}
