#!/bin/bash
# Job name:
#SBATCH --job-name=bowtie_kraken_last5
# Account:
#SBATCH --account=ac_wolflab
# Partition:
#SBATCH --partition=savio3_bigmem
# Wall clock limit:
#SBATCH --time=0:45:00
# Mail:
#SBATCH --mail-type=ALL
#SBATCH --mail-user=sarrahrose@berkeley.edu
# Output logs:
#SBATCH --output=/global/scratch/projects/fc_wolflab/bbioinfo/sarrah/tb/logs/now/output_%x_%j.log
#SBATCH --array=11-16

module load bio/bowtie2/2.5.1-gcc-11.4.0

KRAKENDB="/global/scratch/projects/fc_wolflab/software/kraken2/kraken_prebuilt_db"
SAMPLE_LIST="sample_list.csv"
DATAROOT="/global/scratch/projects/fc_wolflab/bbioinfo/sarrah/tb/data"
OUTPUTDIR="/global/scratch/projects/fc_wolflab/bbioinfo/sarrah/tb/krackuniq/krakencheck"


LINE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" <(tail -n +2 $SAMPLE_LIST))
SAMPLE=$(echo $LINE | cut -d ',' -f 1)
PATH1=$(echo $LINE | cut -d ',' -f 4)
PATH2=$(echo $LINE | cut -d ',' -f 5) 


mkdir -p "${OUTPUTDIR}/${SAMPLE}"

READ1="${DATAROOT}/${PATH1}"
READ2="${DATAROOT}/${PATH2}"

bowtie2 -x /global/scratch/projects/fc_wolflab/bbioinfo/sarrah/tb/bowtie/GRCh38_noalt_as/GRCh38_noalt_as -p 8 -1 ${READ1} \
-2 ${READ2} --un-conc ${OUTPUTDIR}/${SAMPLE}/${SAMPLE}_host_removed -S ${OUTPUTDIR}/${SAMPLE}/${SAMPLE}_human_reads.sam

mv ${OUTPUTDIR}/${SAMPLE}/${SAMPLE}_host_removed.1 ${OUTPUTDIR}/${SAMPLE}/${SAMPLE}_host_removed_R1.fastq
mv ${OUTPUTDIR}/${SAMPLE}/${SAMPLE}_host_removed.2 ${OUTPUTDIR}/${SAMPLE}/${SAMPLE}_host_removed_R2.fastq

echo "Processing sample ${SAMPLE} with reads ${READ1} and ${READ2}"

# Run Kraken2 and log the command
kraken2 --db ${KRAKENDB} --threads 8 --minimum-hit-groups 3 \
--report ${OUTPUTDIR}/${SAMPLE}/${SAMPLE}.k2report \
--paired ${OUTPUTDIR}/${SAMPLE}/${SAMPLE}_host_removed_R1.fastq ${OUTPUTDIR}/${SAMPLE}/${SAMPLE}_host_removed_R2.fastq > ${OUTPUTDIR}/${SAMPLE}/${SAMPLE}.kraken2
