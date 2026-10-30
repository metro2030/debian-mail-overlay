FROM debian:13.7-slim

ARG DEBIAN_FRONTEND=noninteractive
ARG BUILD_CORES

ARG SKALIBS_VER=2.16.0.0
ARG EXECLINE_VER=2.10.0.0
ARG S6_VER=2.15.1.1
ARG RSPAMD_VER=4.2.3
ARG GUCCI_VER=v1.9.0
ARG TCD_VER=v2.11.4

ARG SKALIBS_SHA256_HASH="5a653ff1a7f9ba31b0415e3107f8cb30c91aeb8ace3d05e860850870bc839220"
ARG EXECLINE_SHA256_HASH="cab91d3c1b9d57184ae499900641ab4ab42771c7b2069ec5cc62dffeb3dbe2b4"
ARG S6_SHA256_HASH="8ef6eeb6243d1c372ff8f830607a2a1870d36cf1b640599f3a614dece249e4c4"
ARG RSPAMD_SHA256_HASH="9e75cad61e39ba93ebbfb85674ff9862aa5b1873f1bd80e96edc6c823b011702"
ARG GUCCI_SHA256_HASH="5230c34e6cc39e95edd903b38a7466a1bbe0fb87955d572d4af7d9226077dd4c"
ARG TCD_SHA256_HASH="a22d3b6b558199848979520a4276abeb45f4a2f1af0edb702bd11acb9cbcdbdd"

LABEL description="s6 + rspamd image based on Debian" \
      maintainer="Hardware <contact@meshup.net>" \
      rspamd_version="Rspamd v$RSPAMD_VER built from source" \
      s6_version="s6 v$S6_VER built from source"

ENV LC_ALL=C

RUN NB_CORES=${BUILD_CORES-$(getconf _NPROCESSORS_CONF)} \
    && BUILD_DEPS=" \
    cmake \
    gcc \
    g++ \
    make \
    ragel \
    wget \
    pkg-config \
    libarchive-dev \
    liblua5.1-0-dev \
    libluajit-5.1-dev \
    libglib2.0-dev \
    libevent-dev \
    libsqlite3-dev \
    libicu-dev \
    libssl-dev \
    libhyperscan-dev \
    libjemalloc-dev \
    libmagic-dev \
    libsodium-dev" \
 && apt-get update && apt-get dist-upgrade -y \
 && apt-get install -y -q --no-install-recommends \
    ${BUILD_DEPS} \
    libarchive13t64 \
    libevent-2.1-7t64 \
    libglib2.0-0t64 \
    libssl3t64 \
    libmagic1t64 \
    liblua5.1-0 \
    libluajit-5.1-2 \
    libsqlite3-0 \
    libhyperscan5 \
    libicu76 \
    libjemalloc2 \
    libsodium23 \
    sqlite3 \
    openssl \
    ca-certificates \
    gnupg \
    dirmngr \
    netcat-openbsd \
 && cd /tmp \
 && SKALIBS_TARBALL="v${SKALIBS_VER}.tar.gz" \
 && wget -q https://github.com/skarnet/skalibs/archive/refs/tags/${SKALIBS_TARBALL} \
 && CHECKSUM=$(sha256sum ${SKALIBS_TARBALL} | awk '{print $1}') \
 && if [ "${CHECKSUM}" != "${SKALIBS_SHA256_HASH}" ]; then echo "${SKALIBS_TARBALL} : bad checksum" && exit 1; fi \
 && tar xzf ${SKALIBS_TARBALL} && rm ${SKALIBS_TARBALL} && cd skalibs-${SKALIBS_VER} \
 && ./configure --prefix=/usr --datadir=/etc \
 && make && make install \
 && cd /tmp \
 && EXECLINE_TARBALL="v${EXECLINE_VER}.tar.gz" \
 && wget -q https://github.com/skarnet/execline/archive/refs/tags/${EXECLINE_TARBALL} \
 && CHECKSUM=$(sha256sum ${EXECLINE_TARBALL} | awk '{print $1}') \
 && if [ "${CHECKSUM}" != "${EXECLINE_SHA256_HASH}" ]; then echo "${EXECLINE_TARBALL} : bad checksum" && exit 1; fi \
 && tar xzf ${EXECLINE_TARBALL} && rm ${EXECLINE_TARBALL} && cd execline-${EXECLINE_VER} \
 && ./configure --prefix=/usr --libdir=/usr/local/lib/ \
 && make && make install \
 && cd /tmp \
 && S6_TARBALL="v${S6_VER}.tar.gz" \
 && wget -q https://github.com/skarnet/s6/archive/refs/tags/${S6_TARBALL} \
 && CHECKSUM=$(sha256sum ${S6_TARBALL} | awk '{print $1}') \
 && if [ "${CHECKSUM}" != "${S6_SHA256_HASH}" ]; then echo "${S6_TARBALL} : bad checksum" && exit 1; fi \
 && tar xzf ${S6_TARBALL} && rm ${S6_TARBALL} && cd s6-${S6_VER} \
 && ./configure --prefix=/usr --bindir=/usr/bin --sbindir=/usr/sbin \
 && make && make install \
 && cd /tmp \
 && RSPAMD_TARBALL="${RSPAMD_VER}.tar.gz" \
 && wget -q https://github.com/rspamd/rspamd/archive/${RSPAMD_TARBALL} \
 && CHECKSUM=$(sha256sum ${RSPAMD_TARBALL} | awk '{print $1}') \
 && if [ "${CHECKSUM}" != "${RSPAMD_SHA256_HASH}" ]; then echo "${RSPAMD_TARBALL} : bad checksum" && exit 1; fi \
 && tar xzf ${RSPAMD_TARBALL} && cd rspamd-${RSPAMD_VER} \
 && cmake \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCONFDIR=/etc/rspamd \
    -DRUNDIR=/run/rspamd \
    -DDBDIR=/var/mail/rspamd \
    -DNO_SHARED=ON \
    -DWANT_SYSTEMD_UNITS=OFF \
    -DENABLE_TORCH=ON \
    -DENABLE_HIREDIS=ON \
    -DINSTALL_WEBUI=ON \
    -DENABLE_OPTIMIZATION=ON \
    -DENABLE_HYPERSCAN=ON \
    -DENABLE_JEMALLOC=ON \
    -DJEMALLOC_ROOT_DIR=/jemalloc \
    . \
 && make -j${NB_CORES} \
 && make install \
 && cd /tmp \
 && GUCCI_BINARY="gucci-${GUCCI_VER}-linux-amd64" \
 && wget -q https://github.com/noqcks/gucci/releases/download/${GUCCI_VER}/${GUCCI_BINARY} \
 && CHECKSUM=$(sha256sum ${GUCCI_BINARY} | awk '{print $1}') \
 && if [ "${CHECKSUM}" != "${GUCCI_SHA256_HASH}" ]; then echo "${GUCCI_BINARY} : bad checksum" && exit 1; fi \
 && chmod +x ${GUCCI_BINARY} \
 && mv ${GUCCI_BINARY} /usr/local/bin/gucci \
 && TCD_TARBALL="traefik-certs-dumper_${TCD_VER}_linux_amd64.tar.gz" \
 && wget -q https://github.com/ldez/traefik-certs-dumper/releases/download/${TCD_VER}/${TCD_TARBALL} \
 && CHECKSUM=$(sha256sum ${TCD_TARBALL} | awk '{print $1}') \
 && if [ "${CHECKSUM}" != "${TCD_SHA256_HASH}" ]; then echo "${TCD_TARBALL} : bad checksum" && exit 1; fi \
 && tar xzf ${TCD_TARBALL} \
 && mv traefik-certs-dumper /usr/local/bin/traefik-certs-dumper \
 && chmod +x /usr/local/bin/traefik-certs-dumper \
 && apt-get purge -y ${BUILD_DEPS} \
 && apt-get autoremove -y \
 && apt-get clean \
 && rm -rf /tmp/* /var/lib/apt/lists/* /var/cache/debconf/*-old
