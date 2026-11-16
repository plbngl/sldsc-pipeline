#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$ROOT_DIR/config.sh"

source "$CONFIG"

N=$(find "$PROJECT/beds" -maxdepth 1 -type f -name '*.bed' | wc -l)

mkdir -p "$PROJECT/logs" "$PROJECT/ld_scores"
cd "$PROJECT"

sbatch --array="1-${N}" \
    --export=ALL,CONFIG="$CONFIG" \
    "$ROOT_DIR/scripts/01_annotation_ldscores.sh"
