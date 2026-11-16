#!/bin/bash

ROOT=/ssu/gassu/GAU_tools
REF=/ssu/gassu/supporting_data/LDSC/reference/GRCh38
LDSC=$ROOT/ldsc  ###  https://github.com/CBIIT/ldsc
CONDA_ENV=/ssu/gassu/conda_envs/ldsc

PROJECT=/path/to/example
GWAS_DIR=/ssu/gassu/supporting_data/LDSC/munged

# GWAS selection: all, range, list
GWAS_MODE=range

# For range mode (alphabetically sorted files)
GWAS_START=1
GWAS_END=2

# For list mode (one full GWAS path per line)
GWAS_LIST=/path/to/gwas_list.txt
