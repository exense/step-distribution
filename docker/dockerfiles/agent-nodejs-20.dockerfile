ARG BASE_IMAGE=debian:12-slim
FROM ${BASE_IMAGE} AS common
LABEL author=jonathan.rubiero@exense.ch
# Install required packages
RUN apt -yqq update && apt install -yqq --no-install-recommends curl ca-certificates sudo wget unzip
# Install NVM and Nodejs in one RUN step to minimize layers
ENV NVM_DIR=/usr/local/nvm
ENV NODE_VERSION=20.12.2
ENV PATH=$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH
RUN mkdir -p $NVM_DIR && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash && \
    bash -c ". $NVM_DIR/nvm.sh && nvm install $NODE_VERSION && nvm alias default $NODE_VERSION && nvm use default" && \
    ln -s $NVM_DIR/versions/node/v$NODE_VERSION/bin/node /usr/bin/node && \
    ln -s $NVM_DIR/versions/node/v$NODE_VERSION/bin/npm /usr/bin/npm && \
    ln -s $NVM_DIR/versions/node/v$NODE_VERSION/bin/npx /usr/bin/npx && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* 
# Create agent user
RUN useradd -s /bin/bash -m -U -u 1000 agent
# Create necessary directories
RUN bash -c "mkdir -p /home/agent/{bin,conf,log} && chown -R agent:0 /home/agent"
# Give only required sudo privileges (mind STEP_DP...)
RUN echo "agent ALL=(ALL) NOPASSWD: /usr/bin/apt" > /etc/sudoers.d/agent && \
    echo "agent ALL=(ALL) NOPASSWD: /usr/bin/apt-get" >> /etc/sudoers.d/agent && \
    echo "agent ALL=(ALL) NOPASSWD: /usr/bin/ln" >> /etc/sudoers.d/agent && \
    chmod 440 /etc/sudoers.d/agent
# Specify the final USER as the numeric UID for OpenShift compatibility
USER 1000
# Environment variable
ENV STEP_DP=""
# Defaul agent version to be installed
ARG VERSION=latest
# Default workdir
WORKDIR /home/agent
# Default startup command
CMD ../installDependencies.sh && ./startAgent.sh

# Docker multistage build - staging agent installation
FROM common AS staging
# Uses build server .npmrc configuration to gain access to Nexus staging
COPY --chown=agent:0 .npmrc /home/agent/.npmrc
# Install staging agent
RUN bash -c "npm install step-node-agent@${VERSION} --registry=https://nexus-enterprise-staging.exense.ch/repository/npm-all/ --legacy-peer-deps"
# Cleanup .npmrc configuration
RUN rm -f /home/agent/.npmrc
# Update workdir
WORKDIR /home/agent/bin
# Symbolic link to agent bin folder
RUN ln -s /home/agent/node_modules/step-node-agent/bin/step-node-agent step-node-agent

# Docker multistage build - productive agent installation
FROM common AS production
# Install productive agent
RUN bash -c "npm install step-node-agent@${VERSION}"
# Update workdir
WORKDIR /home/agent/bin
# Symbolic link to agent bin folder
RUN ln -s /home/agent/node_modules/step-node-agent/bin/step-node-agent step-node-agent
