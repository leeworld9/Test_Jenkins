FROM openjdk:11-jre-slim

COPY /build/libs/*.jar application.jar

CMD ["java", "-jar", "/application.jar"]