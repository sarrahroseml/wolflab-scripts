#!/bin/bash 
# Job name:
#SBATCH --job-name=final_singles_methi_last
# Account:
#SBATCH --account=ac_wolflab
# Partition:
#SBATCH --partition=savio3
# Wall clock limit:
#SBATCH --time=8:00:00
# Mail:
#SBATCH --mail-type=ALL
#SBATCH --mail-user=sarrahrose@berkeley.edu
# Output logs:
#SBATCH --output=/global/scratch/projects/fc_wolflab/bbioinfo/sarrah/batches/logs/output_%x_%j.log
#SBATCH --cpus-per-task=32
#SBATCH --mem=16G
#SBATCH --array=95-142

#NOTE: before running, have a fi prepared called anvio_contigdb_paths.txt with name and contigs_path
# Define the base directory for input, output, and config file
CONFIG_FILE="/global/scratch/projects/fc_wolflab/bbioinfo/sarrah/batches/encoded_single_genome.csv"


# Extract the line corresponding to this task
LINE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $CONFIG_FILE)
echo "$LINE" | awk -F',' '{print NF}'

#PArse parameters from the line using a tab as delimiter
SAMPLE_NAME=$(echo "$LINE" | awk -F',' '{print $5}')
PLATE=$(echo "$LINE" | awk -F',' '{print $6}')
LIBRARY_NAME=$(echo "$LINE" | awk -F',' '{print $7}')
GROUP=$(echo "$LINE" | awk -F',' '{print $35}') #ensure this is correct
BATCH_DIR="/global/scratch/projects/fc_wolflab/bbioinfo/sarrah/batches/final_genomes"
CONTIGS_PATH="$BATCH_DIR"/"$PLATE"/"$LIBRARY_NAME"/genome_assembly/contigs.fasta
OUTPUT="/global/scratch/projects/fc_wolflab/bbioinfo/sarrah/batches/anvio/singles/real_gal"
GFF="/global/scratch/projects/fc_wolflab/bbioinfo/sarrah/batches/anvio/gff_parser.py"

#oad relevant packages 
module load anaconda3/2024.02-1-11.4
module load python 

mkdir -p "$OUTPUT"

#Reformat fasta files
source activate anvio-8
anvi-script-reformat-fasta  "$CONTIGS_PATH" \
                              -o "$OUTPUT"/"$SAMPLE_NAME"_contigs.fa \
                              --min-len 0 \
                              --simplify-names

conda deactivate

#Annotate files with prokka 
source activate mamba_prokka 
sleep 5
prokka --prefix PROKKA_"$SAMPLE_NAME" \
       --outdir "$OUTPUT"/PROKKA_"$SAMPLE_NAME" \
       --cpus 32 \
       --metagenome "$OUTPUT"/"$SAMPLE_NAME"_contigs.fa 
conda deactivate 

#Parsing with GFF3 file 
source activate anvio-8
sleep 5
~/.conda/envs/anvio-8/bin/python "$GFF" "$OUTPUT"/PROKKA_"$SAMPLE_NAME"/PROKKA_"$SAMPLE_NAME".gff \
                         --gene-calls "$OUTPUT"/"$SAMPLE_NAME"_gene_calls.txt \
                         --annotation "$OUTPUT"/"$SAMPLE_NAME"_gene_annot.txt

#Generating contigs database

anvi-gen-contigs-database -f "$OUTPUT"/"$SAMPLE_NAME"_contigs.fa  \
-o "$OUTPUT"/"$SAMPLE_NAME"_contigs.db \
--external-gene-calls "$OUTPUT"/"$SAMPLE_NAME"_gene_calls.txt \
--project-name "$SAMPLE_NAME"_DB \
--ignore-internal-stop-codons

#Run additional analysis
anvi-run-hmms -c "$OUTPUT"/"$SAMPLE_NAME"_contigs.db --num-threads 32 
anvi-run-ncbi-cogs -c  "$OUTPUT"/"$SAMPLE_NAME"_contigs.db --num-threads 32 
anvi-scan-trnas -c "$OUTPUT"/"$SAMPLE_NAME"_contigs.db --num-threads 32 
anvi-run-scg-taxonomy -c "$OUTPUT"/"$SAMPLE_NAME"_contigs.db --num-threads 32 
anvi-run-kegg-kofams -c "$OUTPUT"/"$SAMPLE_NAME"_contigs.db --kegg-data-dir /global/scratch/projects/fc_wolflab/bbioinfo/sarrah/batches/anvio/kegg_dir -T 32

contig_db_paths="$OUTPUT"/anvio_contigdb_paths.txt
# Check if the file exists, and if not, create it with headers
if [ ! -f "$contig_db_paths" ]; then
    echo -e "name\tcontigs_db_path" > "$output_file"
fi
NAME="$SAMPLE_NAME"_contigs
CONTIGS_PATH="$OUTPUT"/"$SAMPLE_NAME"_contigs.db

echo -e "${NAME}\t${CONTIGS_PATH}" >> "$contig_db_paths"

add_layers="$OUTPUT"/misc_data_layers.txt 
if [ ! -f "$add_layers" ]; then
    echo -e "genome\tgroup" > "$add_layers"
fi
echo -e "${NAME}\t${GROUP}" >> "$add_layers"

conda deactivate
