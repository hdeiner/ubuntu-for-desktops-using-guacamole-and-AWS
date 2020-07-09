FROM openjdk:8u222-jre-slim-buster

# Install mysql client
RUN apt-get update -yqq && apt-get install default-mysql-client -yqq

# Deploy the executable
COPY zipster-1.0-SNAPSHOT-jar-with-dependencies.jar /
EXPOSE 8080

# Get the service running
CMD ["java", "-jar", "zipster-1.0-SNAPSHOT-jar-with-dependencies.jar"]