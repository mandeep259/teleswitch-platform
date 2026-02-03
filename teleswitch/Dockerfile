# ============================================================
# Stage 1: Builder (Install Vendor RPMs Deterministically)
# ============================================================
FROM almalinux:9 AS builder

LABEL maintainer="Mandeep <mandeep259@dummy.com>"

WORKDIR /build

# Enable repos
RUN dnf -y install epel-release dnf-plugins-core && \
    dnf config-manager --set-enabled crb

# Base dependencies required by vendor RPMs
RUN dnf -y install \
        lame lame-devel \
        speex speex-devel \
        speexdsp speexdsp-devel \
#        gdbm gdbm-devel \
        libedit libjpeg-turbo \
        zlib libzstd libwebp \
    && dnf clean all

# Copy vendor RPMs
COPY rpms/deps /build/rpms/deps
COPY rpms/updated /build/rpms/updated

# Count expected RPMs
RUN ls /build/rpms/deps/*.rpm /build/rpms/updated/*.rpm | wc -l > /tmp/rpm_expected.txt

# Install RPMs (NO silent trust)
RUN dnf -y localinstall /build/rpms/deps/*.rpm  && \
    dnf -y localinstall /build/rpms/updated/*.rpm  && \
    dnf clean all

# Verify core binary exists
RUN test -x /home/teleswitch/teleswitch/usr/bin/freeswitch

# Verify no missing shared libraries
RUN ldd /home/teleswitch/teleswitch/usr/bin/freeswitch | grep "not found" && exit 1 || true

# Verify critical modules exist
RUN test -f /home/teleswitch/teleswitch/usr/lib64/teleswitch/mod/mod_sofia.so

# Create teleswitch alias (branding)
RUN ln -s /home/teleswitch/teleswitch/usr/bin/freeswitch \
          /home/teleswitch/teleswitch/usr/bin/teleswitch


# ============================================================
# Stage 2: Runtime (Minimal + Deterministic)
# ============================================================
FROM almalinux:9

LABEL maintainer="Mandeep <mandeep259@dummy.com>"

# Runtime-only libraries
RUN dnf -y install epel-release dnf-plugins-core && \
    dnf config-manager --set-enabled crb && \
    dnf -y install \
        lame speex speexdsp \
        gdbm-libs libedit libjpeg-turbo \
        zlib libzstd libwebp \
        ca-certificates \
    && dnf clean all

# Create non-root user
RUN useradd -r -u 10001 teleswitch

# Copy vendor application tree
COPY --from=builder /home/teleswitch/teleswitch /home/teleswitch/teleswitch

# Copy required shared libs from builder
COPY --from=builder /lib64/libspandsp.so.3 /lib64/
COPY --from=builder /lib64/libsofia-sip-ua.so.0 /lib64/
COPY --from=builder /lib64/libodbc.so.2 /lib64/
COPY --from=builder /lib64/libtiff.so.5 /lib64/
COPY --from=builder /lib64/libjpeg.so.62 /lib64/
COPY --from=builder /lib64/libjbig.so.2.1 /lib64/
COPY --from=builder /lib64/libwebp.so.7 /lib64/
COPY --from=builder /lib64/libz.so.1 /lib64/
COPY --from=builder /lib64/libzstd.so.1 /lib64/
COPY --from=builder /lib64/libltdl.so.7 /lib64/

# Register vendor lib path
RUN echo "/home/teleswitch/teleswitch/usr/lib64" \
      > /etc/ld.so.conf.d/teleswitch.conf && ldconfig

# Runtime directories
RUN mkdir -p \
      /home/teleswitch/teleswitch/var/log/teleswitch \
      /home/teleswitch/teleswitch/var/run/teleswitch \
      /var/lib/freeswitch/db \
      /var/lib/freeswitch/recordings \
    && chown -R teleswitch:teleswitch \
      /home/teleswitch \
      /var/lib/freeswitch

# Environment
ENV TELE_HOME=/home/teleswitch/teleswitch \
    TELE_CONF=/home/teleswitch/teleswitch/etc/teleswitch \
    TELE_LOG=/home/teleswitch/teleswitch/var/log/teleswitch \
    PATH="/home/teleswitch/teleswitch/usr/bin:${PATH}"

# Ports
EXPOSE 5060/udp
EXPOSE 5060/tcp
EXPOSE 8021/tcp
EXPOSE 17000-22000/udp

# Entrypoint
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY healthcheck.sh /usr/local/bin/healthcheck.sh

RUN chmod +x /usr/local/bin/docker-entrypoint.sh \
    && chmod +x /usr/local/bin/healthcheck.sh

COPY healthcheck.sh /usr/local/bin/healthcheck.sh
RUN chmod +x /usr/local/bin/healthcheck.sh

USER teleswitch

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

HEALTHCHECK --interval=15s --timeout=5s --retries=5 \
  CMD /usr/local/bin/healthcheck.sh || exit 1
