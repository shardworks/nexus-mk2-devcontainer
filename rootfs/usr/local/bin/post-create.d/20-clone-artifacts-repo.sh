#!/usr/bin/env bash
# Ensure the NexusArtifactsRepository (nexus-mk2-artifacts) is present at
# /workspace/nexus-mk2-artifacts so persistent artifacts are available on
# workspace creation without manual steps.
set -euo pipefail

ARTIFACTS_DIR="/workspace/nexus-mk2-artifacts"
ARTIFACTS_REPO="git@github.com:shardworks/nexus-mk2-artifacts.git"

if [ -d "$ARTIFACTS_DIR/.git" ]; then
    echo "[clone-artifacts-repo] Artifacts repo already present at $ARTIFACTS_DIR — pulling latest." >&2
    git -C "$ARTIFACTS_DIR" pull --ff-only || echo "[clone-artifacts-repo] Warning: pull failed, using existing checkout." >&2
else
    echo "[clone-artifacts-repo] Cloning artifacts repo to $ARTIFACTS_DIR..." >&2
    git clone "$ARTIFACTS_REPO" "$ARTIFACTS_DIR"
fi

echo "[clone-artifacts-repo] Done." >&2
