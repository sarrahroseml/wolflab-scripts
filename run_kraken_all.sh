#!/bin/bash
# Job name:
#SBATCH --job-name=ALL_KRAKEN_%a
# Account:
#SBATCH --account=ac_wolflab
# Partition:
#SBATCH --partition=savio3_bigmem 

#SBATCH --time=3:00:00
# Mail:
#SBATCH --mail-type=ALL
#SBATCH --mail-user=sarrahrose@berkeley.edu
# Output logs:
#SBATCH --output=/global/scratch/projects/fc_wolflab/bbioinfo/sarrah/batches/logs/HI_KRAKEN_%a_%j.log
#SBATCH --cpus-per-task=32
#SBATCH --array=2-193

KRAKENDB="/global/scratch/projects/fc_wolflab/software/kraken2/kraken_prebuilt_db"
CONFIG_FILE="/global/scratch/projects/fc_wolflab/bbioinfo/sarrah/batches/Format_Config.csv"
BATCH_DIR="/global/scratch/projects/fc_wolflab/bbioinfo/sarrah/batches/final_genomes"
LINE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $CONFIG_FILE)
echo "$LINE" | awk -F',' '{print NF}'

SAMPLE_NAME=$(echo "$LINE" | awk -F',' '{print $5}')
PLATE=$(echo "$LINE" | awk -F',' '{print $6}')
LIBRARY_NAME=$(echo "$LINE" | awk -F',' '{print $7}')
OUTPUT="$BATCH_DIR/$PLATE/$LIBRARY_NAME/kraken_reports"
mkdir -p "$OUTPUT"
READ1_PATH="$BATCH_DIR/$PLATE/$LIBRARY_NAME/${SAMPLE_NAME}_paired_1.fastq"
READ2_PATH="$BATCH_DIR/$PLATE/$LIBRARY_NAME/${SAMPLE_NAME}_paired_2.fastq"
echo "Processing sample ${SAMPLE_NAME} with reads ${READ1_PATH} and ${READ2_PATH}"
echo "This is your output ${OUTPUT}"

kraken2 --db ${KRAKENDB} --threads 32 --minimum-hit-groups 3 \
--report ${OUTPUT}/"$SAMPLE_NAME".k2report \
--paired $READ1_PATH $READ2_PATH > ${OUTPUT}/${SAMPLE_NAME}.kraken2
