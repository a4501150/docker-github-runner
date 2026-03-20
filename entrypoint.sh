#!/bin/bash
set -e

RUNNER_DIR="/data"
TEMPLATE_DIR="/opt/actions-runner-template"

# Fix Docker socket permissions so the runner process can access it.
# On macOS (Docker Desktop) the socket appears as root:root (GID 0) which
# the runner user cannot access. chmod is simpler and more reliable than
# usermod since group changes don't apply to the already-running process.
if [ -S /var/run/docker.sock ]; then
    sudo chmod 666 /var/run/docker.sock
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
