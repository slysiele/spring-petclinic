# =========================
# Build Stage
# =========================
FROM maven:3.9-eclipse-temurin-21 AS builder

# Set work directory
WORKDIR /app

# Copy Maven wrapper and project files
COPY . .

# Build the project (skip tests for faster build)
RUN mvn clean package -DskipTests -Denforcer.skip=true

# =========================
# Runtime Stage
# =========================
FROM eclipse-temurin:21-jdk

WORKDIR /app

# Copy the packaged jar from the builder stage
COPY --from=builder /app/target/spring-petclinic-*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]

