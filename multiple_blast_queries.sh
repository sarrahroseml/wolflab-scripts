#!/bin/bash
# Job name:
#SBATCH --job-name=Multiple_BLAST
# Account:
#SBATCH --account=ac_wolflab
# Partition:
#SBATCH --partition=savio2_bigmem
# Wall clock limit:
#SBATCH --time=1:30:00
# Mail:
#SBATCH --mail-type=ALL
#SBATCH --mail-user=sarrahrose@berkeley.edu
# Output logs:
#SBATCH --output=/global/scratch/projects/fc_wolflab/bbioinfo/sarrah/tb/logs/output_%x_%j.log
#SBATCH --mem=8G
#SBATCH --array=1-12

module load blast/2.16.0

base_dir="/global/scratch/projects/fc_wolflab/bbioinfo/sarrah/tb/96_tb_samples"
blast_log="/global/scratch/projects/fc_wolflab/bbioinfo/sarrah/tb/96_tb_samples/blast_log.txt"
output_dir="${base_dir}/blast_results"

mkdir -p $output_dir

SAMPLE_LIST="undone_96_samples.csv"

LINE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" <(tail -n +2 $SAMPLE_LIST))
sample_num=$(echo $LINE | cut -d ',' -f 4)
sample_name="S_"$sample_num
sample_dir="$base_dir"/"$sample_name"

echo "Now processing $sample_name" 

tb1_file="${sample_dir}/${sample_name}_TB_1.fasta"
tb2_file="${sample_dir}/${sample_name}_TB_2.fasta"
    
if [[ ! -f $tb1_file ]]; then
  echo "Error: $tb1_file not found. Exiting." >&2
  exit 1
fi

if [[ ! -f $tb2_file ]]; then
  echo "Error: $tb2_file not found. Exiting." >&2
  exit 1
fi

tb1_output="${output_dir}/${sample_name}_TB_1_blast_output.txt"
tb2_output="${output_dir}/${sample_name}_TB_2_blast_output.txt"
echo "Outputting file at path $tb1_output" 
blastn -query $tb1_file -db nt -outfmt "6 qseqid length qcovs qcovhsp evalue bitscore pident sscinames salltitles" -qcov_hsp_perc 50 -out $tb1_output -remote
blastn -query $tb2_file -db nt -outfmt "6 qseqid length qcovs qcovhsp evalue bitscore pident sscinames salltitles" -qcov_hsp_perc 50 -out $tb2_output -remote
echo "Finished processing $sample_name" >> $blast_log
