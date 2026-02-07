#!/bin/bash
set -e

RUNNER_DIR="/data"
TEMPLATE_DIR="/opt/actions-runner-template"

# Copy runner binaries if not present (first run)
if [[ ! -f "$RUNNER_DIR/config.sh" ]]; then
    echo "First run: copying runner binaries to data directory..."
    cp -r "$TEMPLATE_DIR"/. "$RUNNER_DIR"/
fi

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

# Start runner
./run.sh
