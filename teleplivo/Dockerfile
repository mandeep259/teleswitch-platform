FROM eclipse-temurin:8-jre-alpine

WORKDIR /app

# Copy dependency tar and extract
COPY TeleplivoStetup.tar /app/
RUN tar -xf TeleplivoStetup.tar && rm -f TeleplivoStetup.tar

# Copy main jar
COPY TelePlivo.jar /app/

# Copy external config
COPY config /config

# JVM tuning
ENV JAVA_OPTS="-Xms2g -Xmx2g \
-XX:+UseG1GC \
-XX:MaxGCPauseMillis=100 \
-XX:+AlwaysPreTouch \
-XX:+UseContainerSupport \
-Dlog4j.configurationFile=/config/log4j2.xml \
-Dspring.config.location=/config/application.properties"

EXPOSE 8085 8084

ENTRYPOINT ["sh","-c","java $JAVA_OPTS -jar TelePlivo.jar"]

# Alpine doesn't have curl by default, so we install it for the healthcheck
RUN apk add --no-cache curl

HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD curl -f http://localhost:8085/management/health || curl -f http://localhost:8085/actuator/health || exit 1
