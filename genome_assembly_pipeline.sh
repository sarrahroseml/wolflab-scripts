#!/bin/bash
# Job name:
#SBATCH --job-name=Spades_Assembly
# Account:
#SBATCH --account=ac_wolflab
# Partition:
#SBATCH --partition=savio3_bigmem
# Wall clock limit:
#SBATCH --time=2:30:00
# Mail:
#SBATCH --mail-type=ALL
#SBATCH --mail-user=sarrahrose@berkeley.edu
# Output logs:
#SBATCH --output=/global/scratch/projects/fc_wolflab/bbioinfo/sarrah/batches/logs/output_%x_%j.log
#SBATCH --cpus-per-task=16
#SBATCH --mem=50G
#SBATCH --array=2-4%32

module load spades/4.0.0

CONFIG_FILE="/global/scratch/projects/fc_wolflab/bbioinfo/sarrah/batches/These3.csv"
OUTPUT_DIR="/global/scratch/projects/fc_wolflab/bbioinfo/sarrah/batches/final_genomes"
LINE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $CONFIG_FILE)
echo "$LINE" | awk -F',' '{print NF}'

#parse parameters from the line using tab delimiter
READ1_PATH=$(echo "$LINE" | awk -F',' '{print $3}')
READ2_PATH=$(echo "$LINE" | awk -F',' '{print $4}')
SAMPLE_NAME=$(echo "$LINE" | awk -F',' '{print $5}')
PLATE=$(echo "$LINE" | awk -F',' '{print $6}')
LIBRARY_NAME=$(echo "$LINE" | awk -F',' '{print $7}')

SAMPLE_PATH="${OUTPUT_DIR}/${PLATE}/${LIBRARY_NAME}" 
mkdir -p "${SAMPLE_PATH}"
SPADES_DIR="${SAMPLE_PATH}/genome_assembly"
mkdir -p "${SPADES_DIR}"

echo "Debug: READ1_PATH: $READ1_PATH"
echo "Debug: READ2_PATH: $READ2_PATH"
echo "Debug: SAMPLE_NAME: $SAMPLE_NAME"
echo "Debug: PLATE: $PLATE"
echo "Debug: LIBRARY_NAME: $LIBRARY_NAME"

#Run Mark's Pipeline for pre-processing 
mkdir -p ${OUTPUT_DIR}/clean_data
source /global/scratch/projects/fc_wolflab/software/miniforge3/etc/profile.d/conda.sh
conda activate /global/scratch/projects/fc_wolflab/software/miniforge3/envs/mark_biobakery
zcat ${READ1_PATH} | awk '/^@/ {sub(/ 1:N:0[^ ]*/, "/1"); sub(/ .*$/, "");} {print}' >\
     ${OUTPUT_DIR}/clean_data/${SAMPLE_NAME}.R1.fastq
zcat ${READ2_PATH} | awk '/^@/ {sub(/ 2:N:0[^ ]*/, "/2"); sub(/ .*$/, "");} {print}' >\
     ${OUTPUT_DIR}/clean_data/${SAMPLE_NAME}.R2.fastq


kneaddata --input1 ${OUTPUT_DIR}/clean_data/${SAMPLE_NAME}.R1.fastq \
 --input2 ${OUTPUT_DIR}/clean_data/${SAMPLE_NAME}.R2.fastq \
 --output ${SAMPLE_PATH} \
 -db /global/scratch/projects/fc_wolflab/databases/hg37_kd/ \
 --output-prefix ${SAMPLE_NAME} \
 -p 4 --remove-intermediate-output \
 --trimmomatic-options "SLIDINGWINDOW:4:15 MINLEN:100"

conda deactivate 

#Run spades
spades.py --threads 12 -m 46 -o "${SPADES_DIR}" --pe1-1 "${SAMPLE_PATH}/${SAMPLE_NAME}_paired_1.fastq" --pe1-2 "${SAMPLE_PATH}/${SAMPLE_NAME}_paired_2.fastq"
echo "Assembly Completed for sample ${SAMPLE_NAME}"
