FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    curl git unzip nodejs npm gnupg2 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install OpenCode CLI and Bun
RUN npm install -g opencode-ai

# Create a home skeleton for sandbox (we won't rely on its UID/GID)
ARG SANDBOX_USER=sandbox
RUN useradd -m -s /bin/bash "$SANDBOX_USER" || true
RUN chmod 755 /home/sandbox || true

# Simple entrypoint: no chown, no mkdir for opencode dirs
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /workspace

# Start as root; we'll drop to host uid via --user
USER root
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
