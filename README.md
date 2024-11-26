# wolflab-scripts

This encompasses 2 projects 
1. Genome Assembly & Downstream Analysis of 192 Bacteriodetes strains
generate_adapter_files.py - generate FASTA adapter files for trimmomatic
genome_assembly_pipeline.sh - self-descriptive, preprocesses reads, assembles genome with SPades
preparing_contigs_db.sh - preprocessing for Anv'io
anvio_pangenomic.sh - performing pangenomic analysis in Anv'io
add_zero.py - helper script to reformat files
count_k_reads.py - helper script for
run_kraken_all.sh - helper script for running kraken2
run_prokka_all.sh - helper script for genome annotation


2. Quantitifying Presence of Mycobacterium Tuberculosis in 108 Pediatric Fecal Samples
kraken2_bowtie.sh - filter raw reads & analyse with kraken2
extract_reads.sh - extract reads classified as TB by Kraken2
multiple_blast_queries.sh - BLAST extracted reads
parse_blast_output.py - parse blast output from samples 
