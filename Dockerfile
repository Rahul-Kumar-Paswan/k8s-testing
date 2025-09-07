FROM maven:3.9.1-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn clean package -DskipTests

FROM eclipse-temurin:17-jre-jammy
COPY --from=build /app/target/rahulverse-0.0.1-SNAPSHOT.jar app.jar
EXPOSE 8089
ENTRYPOINT [ "java","-jar","app.jar" ]
