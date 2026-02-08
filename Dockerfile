FROM ubuntu:22.04

ARG RUNNER_VERSION=2.329.0
ARG TARGETARCH

# Install dependencies + Docker CLI
# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git jq libicu70 docker.io sudo \
    && rm -rf /var/lib/apt/lists/*

# Create runner user and add to docker group
RUN useradd -m runner && usermod -aG docker runner \
    && echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/runner

# Download and extract runner to template directory (auto-detect architecture)
WORKDIR /opt/actions-runner-template
RUN ARCH=$([ "$TARGETARCH" = "arm64" ] && echo "arm64" || echo "x64") && \
    curl -o actions-runner.tar.gz -L \
    "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${ARCH}-${RUNNER_VERSION}.tar.gz" \
    && tar xzf actions-runner.tar.gz \
    && rm actions-runner.tar.gz

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Runner data directory will be mounted here
WORKDIR /data
RUN chown -R runner:runner /opt/actions-runner-template /data

USER runner
ENTRYPOINT ["/entrypoint.sh"]
