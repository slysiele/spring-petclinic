# =========================
# Build Stage
# =========================
FROM maven:3.9-eclipse-temurin-21 as builder

# Set work directory
WORKDIR /app

# Copy Maven wrapper and project files
COPY . .

# Ensure mvnw has execute permission
RUN chmod +x mvnw

# Build the project (skip tests for faster build)
RUN ./mvnw clean package -DskipTests

# =========================
# Runtime Stage
# =========================
FROM eclipse-temurin:21-jre

WORKDIR /app

# Copy the packaged jar from the builder stage
COPY --from=builder /app/target/spring-petclinic-*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]

