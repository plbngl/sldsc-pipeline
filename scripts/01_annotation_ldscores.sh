#!/bin/bash
#SBATCH --job-name=sldsc_l2
#SBATCH --partition=cpuq
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=08:00:00
#SBATCH --output=logs/l2_%A_%a.out
#SBATCH --error=logs/l2_%A_%a.err

set -euo pipefail

source "${CONFIG:?CONFIG must point to config.sh}"

cd "$PROJECT"
eval "$(conda shell.bash hook)"
conda activate "$CONDA_ENV"

mapfile -t beds < <(find "$PROJECT/beds" -maxdepth 1 -type f -name '*.bed' | sort)

bed=${beds[$((SLURM_ARRAY_TASK_ID - 1))]}
name=$(basename "$bed" .bed)

out="$PROJECT/ld_scores/$name"
mkdir -p "$out"

for chr in {1..22}; do

    prefix="$out/$name.$chr"
    bfile="$REF/plink_files/1000G.EUR.hg38.$chr"

    python "$ROOT/ldsc/make_annot.py" \
        --bed-file "$bed" \
        --bimfile "$bfile.bim" \
        --annot-file "$prefix.annot.gz"

    python "$ROOT/ldsc/ldsc.py" --l2 \
        --bfile "$bfile" \
        --ld-wind-cm 1 \
        --annot "$prefix.annot.gz" \
        --thin-annot \
        --print-snp "$REF/hm3_snps/hm.$chr.snp" \
        --out "$prefix"

done
