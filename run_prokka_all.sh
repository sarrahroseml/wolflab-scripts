#!/bin/bash
# Job name:
#SBATCH --job-name=HELLOPROKKA_%a
# Account:
#SBATCH --account=ac_wolflab
# Partition:
#SBATCH --partition=savio2_bigmem
# Wall clock limit:
#SBATCH --time=2:00:00
# Mail:
#SBATCH --mail-type=ALL
#SBATCH --mail-user=sarrahrose@berkeley.edu
# Output logs:
#SBATCH --output=/global/scratch/projects/fc_wolflab/bbioinfo/sarrah/batches/logs/PROKKAHI_%a_%j.log
#SBATCH --array=2-193

BASE_DIR="/global/scratch/projects/fc_wolflab/bbioinfo/230914_BacteroidesPatnodeLab_GTAC_VPL"
BATCH_DIR="/global/scratch/projects/fc_wolflab/bbioinfo/sarrah/batches/final_genomes"
CONFIG_FILE="/global/scratch/projects/fc_wolflab/bbioinfo/sarrah/batches/Format_Config.csv"

module load anaconda3/2024.02-1-11.4
module load python

LINE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $CONFIG_FILE)
echo "$LINE" | awk -F',' '{print NF}'

READ1_PATH=$(echo "$LINE" | awk -F',' '{print $3}')
READ2_PATH=$(echo "$LINE" | awk -F',' '{print $4}')
SAMPLE_NAME=$(echo "$LINE" | awk -F',' '{print $5}')
PLATE=$(echo "$LINE" | awk -F',' '{print $6}')
LIBRARY_NAME=$(echo "$LINE" | awk -F',' '{print $7}')
OUTPUT="$BATCH_DIR/$PLATE/$LIBRARY_NAME"

source activate mamba_prokka
prokka --prefix PROKKA_"$SAMPLE_NAME" \
       --outdir "$OUTPUT"/PROKKA_"$SAMPLE_NAME" \
       --cpus 2 \
       --metagenome "$OUTPUT"/genome_assembly/contigs.fasta
conda deactivate
