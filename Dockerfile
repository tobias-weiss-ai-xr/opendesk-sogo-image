# SPDX-FileCopyrightText: 2026 openDesk Edu Contributors
# SPDX-License-Identifier: Apache-2.0

# Stage 1: Build from source tarball to ensure OIDC is compiled in.
# Debian bookworm repos do not have SOGo, but trixie/sid do.
# We use the official Debian source tarball from ftp.debian.org
# and compile it. SOGo 5.12.x includes OpenID Connect support.
FROM debian:bookworm-slim AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN set -ex; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        git \
        curl \
        ca-certificates \
        libldap2-dev \
        libssl-dev \
        libmemcached-dev \
        libpq-dev \
        libmariadb-dev-compat \
        libsqlite3-dev \
        libgpgme-dev \
        libsasl2-dev \
        libgnutls28-dev \
        dnsutils \
        libxml2-dev \
    ; \
    rm -rf /var/lib/apt/lists/*

# Download SOGo 5.12.9 source from Debian pool
RUN curl -L -o /tmp/sogo_5.12.9.orig.tar.gz \
    http://ftp.debian.org/debian/pool/main/s/sogo/sogo_5.12.9.orig.tar.gz

# Extract, change to directory, and compile
RUN mkdir -p /build && cd /build && tar xzf /tmp/sogo_5.12.9.orig.tar.gz
RUN cd /build/SOGo-5.12.9 && cmake . && make -j$(nproc)

# Stage 2: Runtime image
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install runtime deps
RUN set -ex; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        supervisor \
        apache2 \
        libapache2-mod-proxy-uwsgi \
        libldap2-dev \
        libssl3 \
        libmemcached11 \
        libpq5 \
        libmariadb-dev-compat \
        sqlite3 \
        libgpgme11 \
        libsasl2-2 \
        libgnutls30 \
        libxml2 \
    ; \
    rm -rf /var/lib/apt/lists/*

# Copy compiled SOGo from builder
RUN mkdir -p /usr/local/src/sogo
COPY --from=builder /build/SOGo-5.12.9 /usr/local/src/sogo
WORKDIR /usr/local/src/sogo
RUN make install

# Enable Apache modules
RUN a2enmod proxy proxy_uwsgi proxy_http headers rewrite

# Add apache-sogo.conf
COPY apache-sogo.conf /etc/apache2/sites-available/sogo.conf
RUN ln -sf /etc/apache2/sites-available/sogo.conf /etc/apache2/sites-enabled/000-sogo.conf

EXPOSE 80

# Entrypoint: supervisord with the provided config
CMD ["/usr/local/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
