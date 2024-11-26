#!/bin/bash
# Job name:
#SBATCH --job-name=Extract_reads_3
# Account:
#SBATCH --account=ac_wolflab
# Partition:
#SBATCH --partition=savio3
# Wall clock limit:
#SBATCH --time=0:20:00
# Mail:
#SBATCH --mail-type=ALL
#SBATCH --mail-user=sarrahrose@berkeley.edu
# Output logs:
#SBATCH --output=/global/scratch/projects/fc_wolflab/bbioinfo/sarrah/tb/logs/output_%x_%j.log
#SBATCH --nodes=1             
#SBATCH --ntasks-per-node=16 
#SBATCH --cpus-per-task=1    
#SBATCH --mem=8G
#SBATCH --array=1-12%32

SAMPLE_LIST="undone_96_samples.csv"
OUTPUT_DIR="/global/scratch/projects/fc_wolflab/bbioinfo/sarrah/tb/96_tb_samples"

LINE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" <(tail -n +2 $SAMPLE_LIST))
SAMPLE_NUM=$(echo $LINE | cut -d ',' -f 4)
SAMPLE=S_"$SAMPLE_NUM"

TB1="$OUTPUT_DIR/$SAMPLE/${SAMPLE}_TB_1.fasta"
TB2="$OUTPUT_DIR/$SAMPLE/${SAMPLE}_TB_2.fasta"


# Check if both TB_1 and TB_2 files exist, & delete if they do
if [[ -f "$TB1" && -f "$TB2" ]]; then
    echo "TB files already exist for $SAMPLE. Deleting them."
    rm -f "$TB1" "$TB2"
fi

# Run extraction if the files do not exist
/global/scratch/projects/fc_wolflab/software/KrakenTools/extract_kraken_reads.py -k "$OUTPUT_DIR/$SAMPLE/${SAMPLE}.kraken2" \
    -s1 "$OUTPUT_DIR/$SAMPLE/${SAMPLE}_paired_1.fastq" -s2 "$OUTPUT_DIR/$SAMPLE/${SAMPLE}_paired_2.fastq" \
    -o "$TB1" -o2 "$TB2" -t 1773

