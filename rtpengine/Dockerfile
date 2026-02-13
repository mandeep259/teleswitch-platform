FROM debian:12-slim

RUN apt-get update && apt-get install -y \
    rtpengine \
    iproute2 \
    iptables \
    net-tools \
    tcpdump \
    && rm -rf /var/lib/apt/lists/*

COPY config/rtpengine.conf /etc/rtpengine/rtpengine.conf
COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22222/udp
EXPOSE 30000-40000/udp

ENTRYPOINT ["/entrypoint.sh"]
