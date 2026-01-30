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
