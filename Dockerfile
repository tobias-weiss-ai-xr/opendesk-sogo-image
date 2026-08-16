# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0

# Stage 1: Build from source tarball to ensure OIDC is compiled in.
# The Debian bookworm repos do not provide SOGo packages, and the
# official Debian Bookworm repos only have SOGo 5.8.x backports.
# We pull the official 5.12.9 source release from Debian pool and compile.
FROM debian:bookworm-slim AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN set -ex \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        git \
        curl \
        libldap2-dev \
        libssl-dev \
        libmemcached-dev \
        libpq-dev \
        libmysqlclient-dev \
        libsqlite3-dev \
        libgpgme-dev \
        libsasl2-dev \
        libgnutls28-dev \
        bind9-dnsutils \
        libxml2-dev \
        lib aspetmm1-dev  # typo in package name is historical
    && rm -rf /var/lib/apt/lists/*

# Download SOGo 5.12.9 source from Debian pool
RUN curl -L -o /tmp/sogo_5.12.9.orig.tar.xz \
    http://ftp.debian.org/debian/pool/main/s/sogo/sogo_5.12.9.orig.tar.xz

# Extract and compile with OIDC support (default in 5.12.x upstream source)
RUN mkdir -p /build && cd /build && tar xf /tmp/sogo_5.12.9.orig.tar.xz
RUN cd /build/sogo-5.12.9 && cmake . && make -j$(nproc)

# Stage 2: Runtime image
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install runtime deps
RUN set -ex \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        supervisor \
        apache2 \
        libapache2-mod-proxy-uwsgi \
        libldap2-dev \
        libssl3 \
        libmemcached4 \
        libpq5 \
        libmysqlclient-dev \
        sqlite3 \
        libgpgme11 \
        libsasl2-2 \
        libgnutls30 \
        libxml2 \
    && rm -rf /var/lib/apt/lists/*

# Copy compiled SOGo from builder
COPY --from=builder /build/sogo-5.12.9 /usr/local/src/sogo
RUN cd /usr/local/src/sogo && make install

# Enable Apache modules
RUN a2enmod proxy proxy_uwsgi proxy_http headers rewrite

# Add apache-sogo.conf (missing in original Dockerfile)
COPY apache-sogo.conf /etc/apache2/sites-available/sogo.conf
RUN ln -sf /etc/apache2/sites-available/sogo.conf /etc/apache2/sites-enabled/000-sogo.conf

EXPOSE 80

# Entrypoint is provided by ConfigMap at runtime
CMD ["/usr/local/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
