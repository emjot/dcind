FROM alpine:3

ARG DOCKER_VERSION=
ARG DOCKER_COMPOSE_VERSION=

# Install Docker and Docker Compose
RUN apk --no-cache add \
    bash \
    curl \
    util-linux \
    device-mapper \
    libffi-dev \
    openssl-dev \
    gcc \
    libc-dev \
    make \
    rust \
    cargo \
    iptables

RUN curl https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz | tar zx && \
    mv /docker/* /bin/ && \
    chmod +x /bin/docker* && \
    mkdir -p /usr/local/lib/docker/cli-plugins && \
    curl -SL https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose && \
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose && \
    rm -rf /root/.cache

# Include functions to start/stop docker daemon
COPY docker-lib.sh /docker-lib.sh
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]
