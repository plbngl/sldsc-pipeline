# S-LDSC Pipeline

A SLURM-based pipeline for testing GWAS heritability enrichment in user-defined genomic annotations using stratified LD score regression (S-LDSC).

The current pipeline provides paths to shared LDSC software,v.3.0.1 (python3.9), GRCh38 reference data, European-ancestry LD scores, and baseline-LD v2.2 annotations.

HT users only need to provide their genomic annotations and configure an output directory, and optionally provide their own GWAS of interest if not present in the shared resources.

## 1. Directory structure

```text
sldsc-pipeline/
├── README.md
├── config.sh
├── submit_annot.sh
├── submit_enrichemnt.sh
├── scripts/
│   ├── 01_annotation_ldscores.sh
│   ├── 02_gwas_enrichemnt.sh
│   └── 03_collect_results.sh
└── example/
    └── beds/
        └── SPI1_eReg.bed
```

Each analysis uses a separate project directory:

```text
my_project/
├── beds/             # Input BED annotations
├── ld_scores/        # Annotation-specific LD scores
├── results/          # S-LDSC regression results
├── logs/             # SLURM logs
└── gwas_lists/       # GWAS lists generated for each submission
```

## 2. Requirements and shared resources

HT users should have access the following shared resources:

| Resource | Location |
|---|---|
| LDSC software | `/ssu/gassu/GAU_tools/ldsc` |
| Conda environment | `/ssu/gassu/conda_envs/ldsc` |
| GRCh38 reference data | `/ssu/gassu/supporting_data/LDSC/reference/GRCh38` |
| Munged GWAS statistics | `/ssu/gassu/supporting_data/LDSC/munged` |

The reference directory contains:

- `plink_files/`: 1000 Genomes Phase 3 European reference genotypes and allele frequencies.
- `baselineLD_v2.2/`: Baseline-LD annotations and precomputed LD scores.
- `weights/`: HapMap3 regression LD weights.
- `hm3_snps/`: Chromosome-specific HapMap3 SNP lists.

Users on the same system can reuse these resources without downloading or copying them.

## 3. Prepare genomic annotations

Create a project directory containing one BED file per annotation:

```bash
mkdir -p /path/to/my_project/beds
```

Each BED file must contain three tab-separated columns without a header:

```text
chr1    105000    105500
chr1    230000    230450
chr2    450000    450800
```

BED files must use GRCh38 coordinates (0-based starts, half-open ends).

Annotations may overlap; each BED file is tested independently against the baseline-LD model.

An example annotation is provided in `example/beds/SPI1_eReg.bed`.

## 4. Configure the pipeline

Edit `config.sh`:

```bash
PROJECT=/path/to/my_project
```

Select GWAS using one of three modes:

| Mode | Description |
|---|---|
| `all` | All `.sumstats.gz` files in the shared GWAS directory |
| `range` | A range of alphabetically sorted GWAS files |
| `list` | A custom text file containing one absolute GWAS path per line |

Example for a subset:

```bash
GWAS_MODE=range
GWAS_START=1
GWAS_END=10
```

Example for a custom selection:

```bash
GWAS_MODE=list
GWAS_LIST=/path/to/gwas_list.txt
```

## 5. Calculate annotation-specific LD scores

Submit:

```bash
bash submit_annot.sh
```

The script automatically detects the number of BED annotations and submits one SLURM array task per annotation.

Each task processes chromosomes 1–22 sequentially, using:

- `make_annot.py` to generate binary SNP annotations.
- `ldsc.py --l2` to calculate annotation-specific LD scores with a 1-cM LD window.

Results are saved in:

```text
my_project/ld_scores/
└── SPI1_eReg/
    ├── SPI1_eReg.1.annot.gz
    ├── SPI1_eReg.1.l2.ldscore.gz
    ├── SPI1_eReg.1.l2.M
    ├── SPI1_eReg.1.l2.M_5_50
    └── ...
```

LD scores are calculated once per annotation and can be reused across different GWAS.

Wait until all annotation jobs finish successfully before proceeding.

## 6. Run GWAS enrichment analysis

Submit:

```bash
bash submit_enrichemnt.sh
```

The submission script selects GWAS according to `config.sh` and creates one independent SLURM task per annotation–GWAS combination.

Each regression jointly models the annotation of interest with baseline-LD v2.2, using European ancestry regression weights and reference allele frequencies.

Results are saved in:

```text
my_project/results/
└── SPI1_eReg/
    ├── Asthma_SPI1_eReg.results
    ├── Asthma_SPI1_eReg.log
    └── ...
```

The number of concurrent jobs is limited to 200. If the total number of submitted tasks exceeds the cluster's submission limit, use `range` or `list` mode to analyze smaller GWAS subsets.

## 7. Collect results

After the enrichment jobs finish, run:

```bash
CONFIG="$PWD/config.sh" bash scripts/03_collect_results.sh
```

This combines the custom annotation results (`L2_0`) across GWAS into:

```text
my_project/sldsc_summary.tsv
```

The output includes the proportion of SNPs, proportion of heritability, enrichment, enrichment P-value, conditional coefficient, standard error and coefficient Z-score.

## 8. Statistical interpretation

S-LDSC provides two complementary statistics:

**Heritability enrichment:** The proportion of SNP heritability attributed to an annotation divided by its proportion of reference SNPs.

**Conditional coefficient (τ):** The additional per-SNP heritability associated with the annotation after adjusting for baseline-LD covariates.

For testing positive conditional contributions, calculate one-sided P-values from the coefficient Z-scores:

```r
p <- pnorm(coefficient_z, lower.tail = FALSE)
```

Multiple-testing correction can be performed using Benjamini–Hochberg FDR, with the testing family defined according to the analysis.

## 9. Adding custom GWAS

Additional GWAS can be processed using the LDSC `munge_sumstats.py` utility and included through `GWAS_MODE=list`.

GWAS summary statistics should be compatible with the European-ancestry reference panel and contain appropriate SNP identifiers, alleles, association statistics and sample sizes.

Custom GWAS do not need to be copied into the shared GWAS directory.

## References

- Bulik-Sullivan et al. (2015). LD Score regression distinguishes confounding from polygenicity in genome-wide association studies. *Nature Genetics*.
- Finucane et al. (2015). Partitioning heritability by functional annotation using genome-wide association summary statistics. *Nature Genetics*.
- Gazal et al. (2017). Linkage disequilibrium–dependent architecture of human complex traits shows action of negative selection. *Nature Genetics*.
- Finucane et al. (2018). Heritability enrichment of specifically expressed genes identifies disease-relevant tissues and cell types. *Nature Genetics*.
