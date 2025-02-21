ARG BASE_IMAGE=debian:12-slim
FROM ${BASE_IMAGE}
LABEL author=jonathan.rubiero@exense.ch
# Install required packages
RUN apt -yqq update && apt install -yqq --no-install-recommends curl ca-certificates sudo wget unzip
# Create agent user
RUN useradd -s /bin/bash -m -U -u 1000 agent
# Give only required sudo privileges (mind STEP_DP...)
RUN echo "agent ALL=(ALL) NOPASSWD: /usr/bin/apt" > /etc/sudoers.d/agent && \
    echo "agent ALL=(ALL) NOPASSWD: /usr/bin/apt-get" >> /etc/sudoers.d/agent && \
    echo "agent ALL=(ALL) NOPASSWD: /usr/bin/ln" >> /etc/sudoers.d/agent && \
    chmod 440 /etc/sudoers.d/agent
# Specify the final USER as the numeric UID for OpenShift compatibility
USER 1000
# Environment variable
ENV STEP_DP=""
# Copy agent binaries
COPY --chown=agent:0 . /home/agent/
# Default workdir
WORKDIR /home/agent/bin/
# Default startup command
CMD ../installDependencies.sh && ./startAgent.sh
