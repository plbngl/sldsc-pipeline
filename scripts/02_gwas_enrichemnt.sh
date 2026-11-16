#!/bin/bash
#SBATCH --job-name=sldsc_h2
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=04:00:00
#SBATCH --output=logs/h2_%A_%a.out
#SBATCH --error=logs/h2_%A_%a.err
set -euo pipefail

source "${CONFIG:?CONFIG must point to config.sh}"

cd "$PROJECT"
eval "$(conda shell.bash hook)"
conda activate "$CONDA_ENV"

mapfile -t beds < <(find "$PROJECT/beds" -maxdepth 1 -type f -name '*.bed' | sort)
mapfile -t gwas < "${GWAS_FILE:?GWAS_FILE must be set}"
ng=${#gwas[@]}
(( ng > 0 )) || { echo 'No GWAS files found' >&2; exit 1; }
i=$(( (SLURM_ARRAY_TASK_ID - 1) / ng ))
j=$(( (SLURM_ARRAY_TASK_ID - 1) % ng ))
name=$(basename "${beds[$i]:?Missing BED}" .bed)
file=${gwas[$j]}
trait=$(basename "$file" .sumstats.gz)
prefix="$PROJECT/ld_scores/$name/$name."

for chr in {1..22}; do
  for suffix in l2.ldscore.gz l2.M l2.M_5_50; do
    test -s "${prefix}${chr}.${suffix}" || { echo "Missing ${prefix}${chr}.${suffix}" >&2; exit 1; }
done
done
mkdir -p "$PROJECT/results/$name"
python "$ROOT/ldsc/ldsc.py" --h2 "$file" \
  --ref-ld-chr "$prefix,$REF/baselineLD_v2.2/baselineLD." \
  --w-ld-chr "$REF/weights/weights.hm3_noMHC." \
  --frqfile-chr "$REF/plink_files/1000G.EUR.hg38." \
  --overlap-annot --print-coefficients \
  --out "$PROJECT/results/$name/${trait}_${name}"

