FROM infrablocks/alpine-aws-s3-config:0.22.0

# Inspired by https://hub.docker.com/r/govuk/gemstash-alpine

# Initialise
ENV GEMSTASH_VERSION 2.1.0

RUN addgroup -S gemstash && \
    adduser -S -G gemstash gemstash

RUN apk update

# Add dependencies required to build Ruby
RUN apk \
    --verbose \
    --no-cache \
    --virtual .ruby-builddeps \
    add \
        autoconf \
        bison \
        bzip2 \
        bzip2-dev \
        ca-certificates \
        coreutils \
        gcc \
        gdbm-dev \
        glib-dev \
        libc-dev \
        libffi-dev \
        libxml2-dev \
        libxslt-dev \
        linux-headers \
        make \
        ncurses-dev \
        libressl \
        libressl-dev \
        procps \
        readline-dev \
        ruby \
        tar \
        xz \
        yaml-dev \
        zlib-dev

# Add dependencies required to run Gemstash
RUN apk
    --verbose \
    --no-cache \
    --virtual .ruby-rundeps \
    add \
        curl \
        ruby \
        ruby-dev \
        sqlite-dev \
        ruby-io-console \
        ruby-json \

# Install Gemstash
RUN gem install --no-ri --no-rdoc gemstash -v ${GEMSTASH_VERSION}

# Remove dependencies required to build Ruby
RUN apk del .ruby-builddeps

# Add start script
COPY start.sh /opt/gemstash/bin/start.sh
RUN chmod +x /opt/gemstash/bin/start.sh

ENV STARTUP_SCRIPT_PATH=/opt/gemstash/bin/start.sh

# Fix ownership
RUN mkdir -p /var/opt/gemstash \
    && chown -R gemstash:gemstash \
        /opt/gemstash \
        /var/opt/gemstash

# Configure image
EXPOSE 9292

HEALTHCHECK --interval=15s --timeout=3s \
    CMD curl -f http://localhost:9292/ || exit 1
