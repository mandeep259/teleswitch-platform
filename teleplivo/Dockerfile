FROM eclipse-temurin:8-jre-alpine

WORKDIR /app

RUN apk add --no-cache curl
RUN mkdir -p /app/logs
RUN mkdir -p /app/TelePlivoCDR
COPY TelePlivo.jar /app/
COPY config /config

ENV JAVA_OPTS="-Xms2g -Xmx2g \
-XX:+UseG1GC \
-Dlog4j.configurationFile=/config/log4j2.xml \
-Dspring.config.location=/config/application.properties"

EXPOSE 8085 8084

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
CMD curl -f http://localhost:8085/actuator/health || exit 1

ENTRYPOINT ["sh","-c","java $JAVA_OPTS -jar TelePlivo.jar"]
