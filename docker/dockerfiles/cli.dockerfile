# BASE_IMAGE is given as a build-arg, keeping default here for local builds
ARG BASE_IMAGE=debian:12-slim
FROM ${BASE_IMAGE} AS cli
LABEL author=jonathan.rubiero@exense.ch
# User root
USER 0
# Install required packages
RUN apt -yqq update && \
    apt install --no-install-recommends -yqq  \
        ca-certificates \
        curl && \
    rm -rf /var/lib/apt/lists/*
# Set Java environment
ENV JAVA_HOME=/usr/java/jdk-21
# Install Java 21
RUN curl -L --output /tmp/jdk.tgz "https://api.adoptium.net/v3/binary/latest/21/ga/linux/x64/jdk/hotspot/normal/eclipse" && \
    mkdir -p "$JAVA_HOME" && \
    tar --extract --file /tmp/jdk.tgz --directory "$JAVA_HOME" --strip-components 1 && \
    rm -rf /tmp/jdk.tgz \
# CLI_VERSION is given as a build-arg, keeping default here for local builds
ARG CLI_VERSION=master-DEVELOPMENT
ENV CLI_PATH=/usr/local/bin/step
# NEXUS_HOST is given as a build-arg, keeping default here for local builds
ARG NEXUS_HOST=nexus-enterprise-staging.stepcloud-test.ch
# Download the CLI
RUN curl -fsSL -u "delivery:100%FTPonly" -o ${CLI_PATH} https://${NEXUS_HOST}/repository/distribution/step/${CLI_VERSION}/step && \
    chmod +x ${CLI_PATH}
# Create step user
RUN useradd -s /bin/bash -m -U -u 1000 step
# Switch to regular user
USER 1000
# Update path
ENV PATH=$JAVA_HOME/bin:$PATH
