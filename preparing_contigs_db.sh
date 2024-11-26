#!/bin/bash
#SBATCH --job-name=process_group_%a
#SBATCH --account=ac_wolflab
#SBATCH --partition=savio3
#SBATCH --time=1:00:00  
#SBATCH --mail-user=sarrahrose@berkeley.edu
#SBATCH --output=/global/scratch/projects/fc_wolflab/bbioinfo/sarrah/batches/logs/HELLO_ANVIO_process_group_%a_%j.log
#SBATCH --cpus-per-task=32
#SBATCH --mem=80G
#SBATCH --array=2-100%32 

module load anaconda3/2024.02-1-11.4
module load python

# check if assay group name is provided
if [ $# -ne 1 ]; then
    echo "Usage: sbatch anvio_baby_script.sh \"Assay Group Name\""
    exit 1
fi

ASSAY_GROUP_ORIGINAL="$1"
ASSAY_GROUP_SANITIZED=$(echo "$ASSAY_GROUP_ORIGINAL" | tr '[:upper:] ' '[:lower:]_' | tr -cd '[:alnum:]_')
echo "original assay grp name: '$ASSAY_GROUP_ORIGINAL'"
echo "santised assay grp name: '$ASSAY_GROUP_SANITIZED'"

if [[ -z "$ASSAY_GROUP_SANITIZED" ]]; then
    echo "Error: Sanitized assay group name is empty."
    exit 1
fi


CONFIG_FILE="/global/scratch/projects/fc_wolflab/bbioinfo/sarrah/batches/encoded_genomes_1.csv"
BATCH_DIR="/global/scratch/projects/fc_wolflab/bbioinfo/sarrah/batches/final_genomes"
OUTPUT="/global/scratch/projects/fc_wolflab/bbioinfo/sarrah/batches/anvio/all/central_1"
OUTPUT_BASE="/global/scratch/projects/fc_wolflab/bbioinfo/sarrah/batches/anvio/all/group1/$ASSAY_GROUP_SANITIZED"
GFF_PARSER="/global/scratch/projects/fc_wolflab/bbioinfo/sarrah/batches/anvio/gff_parser.py"

echo "central output dir: '$OUTPUT'"
echo "Assay Group Output Directory: '$OUTPUT_BASE'"

mkdir -p "$OUTPUT"
mkdir -p "$OUTPUT_BASE"

echo "Directories created successfully."

append_to_log() {
    local log_file="$1"
    local entry="$2"
    local lock_file="$3"

    (
        flock -n 200 || { echo "failed to acquire lock for $log_file"; exit 1; }
        if ! grep -q "^$entry$" "$log_file"; then
            echo -e "$entry" >> "$log_file"
        fi
    ) 200>"$lock_file"
}

initialize_log() {
    local log_file="$1"
    local header="$2"

    if [ ! -f "$log_file" ]; then
        echo -e "$header" > "$log_file"
    fi
}

contig_db_paths="$OUTPUT_BASE/anvio_contigdb_paths.txt"
contig_db_paths_lock="$OUTPUT_BASE/anvio_contigdb_paths.lock"

add_layers="$OUTPUT_BASE/misc_data_layers.txt"
add_layers_lock="$OUTPUT_BASE/misc_data_layers.lock"

initialize_log "$contig_db_paths" "name\tcontigs_db_path"
initialize_log "$add_layers" "genome\tgroup"

LINE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$CONFIG_FILE")

SAMPLE_NAME=$(echo "$LINE" | awk -F',' '{print $5}')
PLATE=$(echo "$LINE" | awk -F',' '{print $6}')
LIBRARY_NAME=$(echo "$LINE" | awk -F',' '{print $7}')

#find col index for assay group
HEADER=$(head -n 1 "$CONFIG_FILE")
IFS=',' read -r -a columns <<< "$HEADER"

ASSAY_COLUMN=0
for i in "${!columns[@]}"; do
    sanitized_column=$(echo "${columns[$i]}" | tr '[:upper:] ' '[:lower:]_' | tr -cd '[:alnum:]_') 

    if [[ "$sanitized_column" == "$ASSAY_GROUP_SANITIZED" ]]; then
        #1-based indexing for awk
        ASSAY_COLUMN=$((i + 1))  
        break
    fi
done

if [[ "$ASSAY_COLUMN" -eq 0 ]]; then
    echo "Error: Assay group '$ASSAY_GROUP_ORIGINAL' not found"
    exit 1
fi

#extract assay value
ASSAY_VALUE=$(echo "$LINE" | awk -F',' -v col="$ASSAY_COLUMN" '{print $col}')

#skip processing if assay value is empty 
if [[ -z "$ASSAY_VALUE" || "$ASSAY_VALUE" == "NA" ]]; then
    echo "Sample $SAMPLE_NAME: Assay '$ASSAY_GROUP_ORIGINAL' has invalid value. Skipping."
    exit 0
fi

CONTIGS_PATH="$BATCH_DIR/$PLATE/$LIBRARY_NAME/genome_assembly/contigs.fasta"
CONTIGS_FA="$OUTPUT/${SAMPLE_NAME}_contigs.fa"
PROKKA_OUTDIR="$OUTPUT/PROKKA_${SAMPLE_NAME}"
CONTIGS_DB_PATH="$OUTPUT_BASE/${SAMPLE_NAME}_contigs.db"
GENE_CALLS="$OUTPUT/${SAMPLE_NAME}_gene_calls.txt"
ANNOTATION="$OUTPUT/${SAMPLE_NAME}_gene_annot.txt"
NAME="${SAMPLE_NAME}_contigs"

PROKKA_EXISTS=0
CONTIGS_FA_EXISTS=0
GENE_CALLS_EXISTS=0
ANNOTATION_EXISTS=0

if [[ -d "$PROKKA_OUTDIR" ]]; then
    PROKKA_EXISTS=1
fi

if [[ -f "$CONTIGS_FA" ]]; then
    CONTIGS_FA_EXISTS=1
fi

if [[ -f "$GENE_CALLS" && -f "$ANNOTATION" ]]; then
    GENE_CALLS_EXISTS=1
    ANNOTATION_EXISTS=1
fi

#if all prereq files/directories exist, skip 
if [[ "$PROKKA_EXISTS" -eq 1 && "$CONTIGS_FA_EXISTS" -eq 1 && "$GENE_CALLS_EXISTS" -eq 1 && "$ANNOTATION_EXISTS" -eq 1 ]]; then
    echo "All prerequisite files for Sample: $SAMPLE_NAME in Assay Group: $ASSAY_GROUP_ORIGINAL exist. Skipping reformatting, Prokka annotation, and GFF parsing."
else
    echo "Processing Sample: $SAMPLE_NAME in Assay Group: $ASSAY_GROUP_ORIGINAL"
        if [[ "$CONTIGS_FA_EXISTS" -eq 0 ]]; then
        echo "Reformatting FASTA for $NAME"
        source activate anvio-8
        anvi-script-reformat-fasta "$CONTIGS_PATH" \
            -o "$CONTIGS_FA" \
            --min-len 0 \
            --simplify-names || { echo "Reformatting failed for $NAME in '$ASSAY_GROUP_ORIGINAL'"; exit 1; }
        conda deactivate
    else
        echo "Contigs FA file already exists. Skipping reformatting."
    fi
    
  
    if [[ "$PROKKA_EXISTS" -eq 0 ]]; then
        echo "Annotating with Prokka for $NAME"
        source activate mamba_prokka 
        prokka --prefix PROKKA_"$SAMPLE_NAME" \
               --outdir "$PROKKA_OUTDIR" \
               --cpus 8 \
               --metagenome "$CONTIGS_FA" || { echo "Prokka failed for $NAME in '$ASSAY_GROUP_ORIGINAL'"; exit 1; }
        conda deactivate 
    else
        echo "Prokka annotation directory already exists. Skipping Prokka."
    fi
    
    if [[ "$GENE_CALLS_EXISTS" -eq 0 || "$ANNOTATION_EXISTS" -eq 0 ]]; then
        echo "Parsing GFF3 for $NAME"
        source activate anvio-8
	echo "Conda Environment Prefix: $CONDA_PREFIX"
	echo "Using Python executable: $(which python)"
        echo "Conda Info:"
	conda info

        ~/.conda/envs/anvio-8/bin/python "$GFF_PARSER" "$PROKKA_OUTDIR/PROKKA_${SAMPLE_NAME}.gff" \
            --gene-calls "$GENE_CALLS" \
            --annotation "$ANNOTATION" || { echo "GFF parsing failed for $NAME in '$ASSAY_GROUP_ORIGINAL'"; exit 1; }
        conda deactivate
    else
        echo "Gene calls and annotation files already exist. Skipping GFF parsing."
    fi
fi

if [[ -f "$CONTIGS_DB_PATH" ]]; then
    echo "Contigs DB already exists for $NAME in '$ASSAY_GROUP_ORIGINAL'. Skipping contigs DB generation."
else
    echo "Generating Anvi'o contigs database for $NAME in '$ASSAY_GROUP_ORIGINAL'"
    source activate anvio-8
    anvi-gen-contigs-database -f "$CONTIGS_FA" \
        -o "$CONTIGS_DB_PATH" \
        --external-gene-calls "$GENE_CALLS" \
        --project-name "${SAMPLE_NAME}_DB" \
        --ignore-internal-stop-codons || { echo "Generating contigs DB failed for $NAME in '$ASSAY_GROUP_ORIGINAL'"; exit 1; }
    conda deactivate
fi

if [[ -f "$CONTIGS_DB_PATH" ]]; then
    
    ANVIO_ANALYSES_MARKER="$OUTPUT_BASE/${SAMPLE_NAME}_anvio_analyses_completed.marker"
    
    if [[ ! -f "$ANVIO_ANALYSES_MARKER" ]]; then
        echo "Running additional Anvi'o analyses for $NAME in '$ASSAY_GROUP_ORIGINAL'"
        source activate anvio-8
        anvi-run-hmms -c "$CONTIGS_DB_PATH" --num-threads 32 || { echo "Anvi-run-hmms failed for $NAME in '$ASSAY_GROUP_ORIGINAL'"; exit 1; }
        anvi-run-ncbi-cogs -c "$CONTIGS_DB_PATH" --num-threads 32 || { echo "Anvi-run-ncbi-cogs failed for $NAME in '$ASSAY_GROUP_ORIGINAL'"; exit 1; }
        anvi-scan-trnas -c "$CONTIGS_DB_PATH" --num-threads 32 || { echo "Anvi-scan-trnas failed for $NAME in '$ASSAY_GROUP_ORIGINAL'"; exit 1; }
        anvi-run-scg-taxonomy -c "$CONTIGS_DB_PATH" --num-threads 32 || { echo "Anvi-run-scg-taxonomy failed for $NAME in '$ASSAY_GROUP_ORIGINAL'"; exit 1; }
        anvi-run-kegg-kofams -c "$CONTIGS_DB_PATH" \
            --kegg-data-dir /global/scratch/projects/fc_wolflab/bbioinfo/sarrah/batches/anvio/kegg_dir \
            -T 32 || { echo "Anvi-run-kegg-kofams failed for $NAME in '$ASSAY_GROUP_ORIGINAL'"; exit 1; }
        conda deactivate

        touch "$ANVIO_ANALYSES_MARKER"
    else
        echo "Additional Anvi'o analyses already completed for $NAME in '$ASSAY_GROUP_ORIGINAL'. Skipping."
    fi
else
    echo "Contigs DB does not exist for $NAME in '$ASSAY_GROUP_ORIGINAL'. Skipping additional Anvi'o analyses."
fi

append_to_log "$contig_db_paths" "${NAME}\t${CONTIGS_DB_PATH}" "$contig_db_paths_lock"
append_to_log "$add_layers" "${NAME}\t${ASSAY_VALUE}" "$add_layers_lock"

echo "Processing completed for Sample: $SAMPLE_NAME in Assay Group: $ASSAY_GROUP_ORIGINAL"
