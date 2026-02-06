FROM kamailio/kamailio-ci:5.4.3-alpine

WORKDIR /etc/kamailio

RUN apk add --no-cache \
    bash \
    curl \
    iputils \
    net-tools \
    tcpdump

# Copy config from correct directory
COPY config/kamailio.cfg /etc/kamailio/kamailio.cfg

EXPOSE 5060/udp
EXPOSE 5060/tcp
EXPOSE 5061/tcp

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD pgrep kamailio || exit 1

CMD ["kamailio", "-DD", "-E", "-f", "/etc/kamailio/kamailio.cfg"]
