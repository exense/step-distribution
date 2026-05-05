ARG BASE_IMAGE=debian:12-slim
FROM ${BASE_IMAGE} AS common
LABEL author=jonathan.rubiero@exense.ch
# Install required packages
RUN apt -yqq update && \
    apt install --no-install-recommends -yqq  \
        ca-certificates \
        wget \
        curl \
        zip \
        unzip \
        procps \
        sudo \
        vim \
        dnsutils \
        stoken \
        locales \
        ghostscript=10.0.0~dfsg-11+deb12u8 \
        postgresql-client && \
    rm -rf /var/lib/apt/lists/*
# Configure locales
RUN sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen && \
    sed -i 's/^# *\(de_DE.UTF-8\)/\1/' /etc/locale.gen && \
    locale-gen
# Set environment variables for locale (user 0)
ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
# Create controller user
RUN useradd -s /bin/bash -m -U -u 1000 controller
# Give only required sudo privileges (mind STEP_DP...)
RUN echo "controller ALL=(ALL) NOPASSWD: /usr/bin/apt" > /etc/sudoers.d/controller && \
    echo "controller ALL=(ALL) NOPASSWD: /usr/bin/apt-get" >> /etc/sudoers.d/controller && \
    echo "controller ALL=(ALL) NOPASSWD: /usr/bin/ln" >> /etc/sudoers.d/controller && \
    chmod 440 /etc/sudoers.d/controller
# Create necessary directories and ensure permissions are set for non-root users
RUN mkdir -p /home/controller/.local/bin/ && \
    mkdir /home/controller/log && \
    mkdir /home/controller/licenses && \
    chown -R controller:0 /home/controller && \
    chmod -R g+wx /home/controller
# Set USER as USERID
USER 1000
# Set environment variables for locale (user 1000)
ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
# Set PATH
ENV PATH="$PATH:/home/controller/.local/bin/"
# Environment variable
ENV STEP_DP=""
# Copy controller binaries
COPY --chown=controller:0 . /home/controller/
# Default workdir
WORKDIR /home/controller/bin/
# Add necessary execution rights
RUN chmod +x /home/controller/installDependencies.sh /home/controller/bin/startController.sh
# Default startup command
CMD ../installDependencies.sh && ./startController.sh

# Multistage build - java 21
FROM common AS java-21
# Switch to root user
USER 0
# Set Java environment
ENV JAVA_HOME=/usr/java/jdk-21
# Install Java 21
RUN curl -L --output /tmp/jdk.tgz "https://api.adoptium.net/v3/binary/latest/21/ga/linux/x64/jdk/hotspot/normal/eclipse" && \
    mkdir -p "$JAVA_HOME" && \
    tar --extract --file /tmp/jdk.tgz --directory "$JAVA_HOME" --strip-components 1 && \
    rm -rf /tmp/jdk.tgz
# Switch to regular user
USER 1000
# Update path environment variable
ENV PATH=$JAVA_HOME/bin:$PATH

# Multistage build - java 25
FROM common AS java-25
# Switch to root user
USER 0
# Set Java environment
ENV JAVA_HOME=/usr/java/jdk-25
# Install Java 21
RUN curl -L --output /tmp/jdk.tgz "https://api.adoptium.net/v3/binary/latest/25/ga/linux/x64/jdk/hotspot/normal/eclipse" && \
    mkdir -p "$JAVA_HOME" && \
    tar --extract --file /tmp/jdk.tgz --directory "$JAVA_HOME" --strip-components 1 && \
    rm -rf /tmp/jdk.tgz \
# Switch to regular user
USER 1000
# Update path
ENV PATH=$JAVA_HOME/bin:$PATH
