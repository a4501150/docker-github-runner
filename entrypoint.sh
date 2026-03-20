#!/bin/bash
set -e

RUNNER_DIR="/data"
TEMPLATE_DIR="/opt/actions-runner-template"

# Fix Docker socket permissions: detect socket GID and add runner to that group.
# On Linux the socket GID matches a real docker group; on macOS (Docker Desktop)
# it appears as root (GID 0). This handles both cases.
if [ -S /var/run/docker.sock ]; then
    SOCK_GID=$(stat -c '%g' /var/run/docker.sock)
    if ! id -nG runner | grep -qw "$(getent group "$SOCK_GID" 2>/dev/null | cut -d: -f1)"; then
        if [ "$SOCK_GID" -eq 0 ]; then
            sudo usermod -aG root runner
        else
            EXISTING_GROUP=$(getent group "$SOCK_GID" | cut -d: -f1)
            if [ -z "$EXISTING_GROUP" ]; then
                sudo groupadd -g "$SOCK_GID" dockerhost
                EXISTING_GROUP="dockerhost"
            fi
            sudo usermod -aG "$EXISTING_GROUP" runner
        fi
    fi
fi

# Ensure data directory is owned by runner user
sudo chown -R runner:runner "$RUNNER_DIR" 2>/dev/null || true

# Copy runner binaries if not present (first run)
if [[ ! -f "$RUNNER_DIR/config.sh" ]]; then
    echo "First run: copying runner binaries to data directory..."
    cp -r "$TEMPLATE_DIR"/. "$RUNNER_DIR"/
fi

# Ensure _work directory (may be a named volume) is owned by runner
sudo chown runner:runner "$RUNNER_DIR/_work" 2>/dev/null || true

cd "$RUNNER_DIR"

# Check if already configured (credentials exist)
if [[ -f ".credentials" ]]; then
    echo "Runner already configured, starting..."
else
    echo "Configuring runner..."

    if [[ -z "$RUNNER_TOKEN" ]]; then
        echo "ERROR: RUNNER_TOKEN is required for initial configuration"
        exit 1
    fi

    # Clean up stale config files that may have been left by auto-updates
    rm -f .runner_migrated

    ./config.sh --url "${RUNNER_URL}" --token "${RUNNER_TOKEN}" \
        --name "${RUNNER_NAME:-$(hostname)}" \
        --labels "${RUNNER_LABELS:-self-hosted}" \
        --unattended --replace
fi

# Graceful shutdown: forward SIGTERM/SIGINT to the runner process
# so it deregisters its session with GitHub before exiting
trap 'kill -TERM "$RUNNER_PID" 2>/dev/null; wait "$RUNNER_PID"' TERM INT

# Start runner
./run.sh &
RUNNER_PID=$!
wait "$RUNNER_PID"
