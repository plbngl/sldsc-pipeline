#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$ROOT_DIR/config.sh"

source "$CONFIG"

mkdir -p "$PROJECT/logs" "$PROJECT/results" "$PROJECT/gwas_lists"

GWAS_FILE=$(mktemp "$PROJECT/gwas_lists/gwas_XXXXXXXX.txt")

case "$GWAS_MODE" in
    all)
        find "$GWAS_DIR" -maxdepth 1 -type f -name '*.sumstats.gz' | sort > "$GWAS_FILE"
        ;;
    range)
        find "$GWAS_DIR" -maxdepth 1 -type f -name '*.sumstats.gz' | sort |
            sed -n "${GWAS_START},${GWAS_END}p" > "$GWAS_FILE"
        ;;
    list)
        cp "$GWAS_LIST" "$GWAS_FILE"
        ;;
    *)
        echo "Invalid GWAS_MODE: $GWAS_MODE" >&2
        exit 1
        ;;
esac

NG=$(wc -l < "$GWAS_FILE")
NB=$(find "$PROJECT/beds" -maxdepth 1 -type f -name '*.bed' | wc -l)

(( NG > 0 && NB > 0 )) || { echo "No GWAS or BED files found" >&2; exit 1; }

cd "$PROJECT"

sbatch --array="1-$((NB * NG))%200" \
    --export=ALL,CONFIG="$CONFIG",GWAS_FILE="$GWAS_FILE" \
    "$ROOT_DIR/scripts/02_gwas_enrichemnt.sh"
