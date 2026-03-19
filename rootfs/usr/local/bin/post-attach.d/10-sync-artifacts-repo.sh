#!/usr/bin/env bash
# Sync the NexusArtifactsRepository on each workspace attach so persistent
# artifacts are current without manual intervention.
set -euo pipefail

ARTIFACTS_DIR="/workspace/nexus-mk2-notes"

if [ -d "$ARTIFACTS_DIR/.git" ]; then
    echo "[sync-artifacts-repo] Pulling latest artifacts from NexusArtifactsRepository..." >&2
    git -C "$ARTIFACTS_DIR" pull --ff-only || echo "[sync-artifacts-repo] Warning: pull failed, using existing checkout." >&2
    echo "[sync-artifacts-repo] Done." >&2
else
    echo "[sync-artifacts-repo] Artifacts repo not found at $ARTIFACTS_DIR — skipping sync (run post-create to initialize)." >&2
fi
