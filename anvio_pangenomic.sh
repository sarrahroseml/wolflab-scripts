#!/bin/bash 
# Job name:
#SBATCH --job-name=GALACTAN
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
#SBATCH --mem=80G

#check if assay group name is given
if [ $# -ne 1 ]; then
    echo "Usage: sbatch anvio_baby_script.sh \"Assay Group Name\""
    exit 1
fi

#parse assay group name
ASSAY_GROUP_ORIGINAL="$1"

ASSAY_GROUP_SANITIZED=$(echo "$ASSAY_GROUP_ORIGINAL" | tr '[:upper:] ' '[:lower:]_' | tr -cd '[:alnum:]_')

echo "Original Assay Group Name: '$ASSAY_GROUP_ORIGINAL'"
echo "Sanitized Assay Group Name: '$ASSAY_GROUP_SANITIZED'"

if [[ -z "$ASSAY_GROUP_SANITIZED" ]]; then
    echo "Error: Sanitized assay group name is empty. Please check the input."
    exit 1
fi

OUTPUT="/global/scratch/projects/fc_wolflab/bbioinfo/sarrah/batches/anvio/all/group1/$ASSAY_GROUP_SANITIZED" #make sure to check output dir 
BASE="/global/scratch/projects/fc_wolflab/bbioinfo/sarrah/batches/anvio/all/analysis/group1"

mkdir -p "$BASE"
echo "Successfully created dir at $BASE"

GENOME_STORAGEDB_NAME="$ASSAY_GROUP_SANITIZED-GENOMES" #I think you need the -GENOMES at the end 
GENOME_STORAGE_PATH="${BASE}/${GENOME_STORAGEDB_NAME}.db"
contig_db_paths="$OUTPUT"/anvio_contigdb_paths.txt 
misc_layers="$OUTPUT"/misc_data_layers.txt
func_enrich_cog_output="$BASE/$ASSAY_GROUP_SANITIZED-COGfunctions.txt"
func_enrich_kegg_output="$BASE/$ASSAY_GROUP_SANITIZED-meth_kegfunctions.txt"

module load anaconda3/2024.02-1-11.4
module load python 
source activate anvio-8
sleep 5


#Create genome storage database 
anvi-gen-genomes-storage -e ${contig_db_paths} \
                         -o ${GENOME_STORAGE_PATH} \
			--gene-caller Prodigal  
#Run pangenomic analysis 
anvi-pan-genome -g ${GENOME_STORAGE_PATH} -n ${GENOME_STORAGEDB_NAME} -o ${BASE}/${GENOME_STORAGEDB_NAME} --num-threads 32

#Compute genome similarity
anvi-compute-genome-similarity --external-genomes ${contig_db_paths} \
                               --program pyANI \
                               --output-dir ANI \
                               --num-threads 32 \
			       --pan-db ${GENOME_STORAGEDB_NAME}/${GENOME_STORAGEDB_NAME}-PAN.db

#Compute Functional Enrichment 
anvi-import-misc-data ${misc_layers} \
                      -p ${GENOME_STORAGEDB_NAME}/${GENOME_STORAGEDB_NAME}-PAN.db \
                      --target-data-table layers

anvi-compute-functional-enrichment-in-pan -p ${GENOME_STORAGEDB_NAME}/${GENOME_STORAGEDB_NAME}-PAN.db \
                                          -g $GENOME_STORAGE_PATH \
                                          --category group \
                                          --annotation-source COG20_FUNCTION \
                                          -o ${func_enrich_cog_output}
anvi-compute-functional-enrichment-in-pan -p ${GENOME_STORAGEDB_NAME}/${GENOME_STORAGEDB_NAME}-PAN.db \
                                          -g $GENOME_STORAGE_PATH \
                                          --category group \
                                          --annotation-source KOfam \
                                          -o ${func_enrich_kegg_output}
conda deactivate
