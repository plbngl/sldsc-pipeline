#!/bin/bash
set -euo pipefail

source "${CONFIG:?CONFIG must point to config.sh}"

OUT="$PROJECT/sldsc_summary.tsv"

printf 'Annotation\tGWAS\tProp_SNPs\tProp_h2\tProp_h2_SE\tEnrichment\tEnrichment_SE\tEnrichment_p\tCoefficient\tCoefficient_SE\tCoefficient_Z\n' > "$OUT"

find "$PROJECT/results" -type f -name '*.results' -print0 |
while IFS= read -r -d '' file; do

    annotation=$(basename "$(dirname "$file")")
    trait=$(basename "$file" "_${annotation}.results")

    awk -v a="$annotation" -v t="$trait" '
        BEGIN {OFS="\t"}
        $1=="L2_0" {
            print a,t,$2,$3,$4,$5,$6,$7,$8,$9,$10
        }
    ' "$file"

done >> "$OUT"

echo "Results saved to $OUT"
