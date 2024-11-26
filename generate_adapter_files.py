import pandas as pd
import os
import hashlib

config_path = '/global/scratch/projects/fc_wolflab/bbioinfo/sarrah/batches/slurmconfig.csv'
config_df = pd.read_csv(config_path, sep=',')
print("Column names:", config_df.columns)

def create_hash(text):
    return hashlib.sha1(text.encode()).hexdigest()

fasta_dir = '/global/scratch/projects/fc_wolflab/bbioinfo/sarrah/batches/adapter_files/'

#Nextera sequences 
additional_sequences = """
>PrefixNX/1
AGATGTGTATAAGAGACAG
>PrefixNX/2
AGATGTGTATAAGAGACAG
>Trans1
TCGTCGGCAGCGTCAGATGTGTATAAGAGACAG
>Trans1_rc
CTGTCTCTTATACACATCTGACGCTGCCGACGA
>Trans2
GTCTCGTGGGCTCGGAGATGTGTATAAGAGACAG
>Trans2_rc
CTGTCTCTTATACACATCTCCGAGCCCACGAGAC
"""

for index, row in config_df.iterrows():
    library_name = row["Sample name"]
    index_1 = row['Index 1'].replace(" ", "")
    index_2 = row['Index 2'].replace(" ", "")
    fasta_content = f">v1_{library_name}_i7\n{index_1}\n>v1_{library_name}_i5\n{index_2}\n{additional_sequences}"
    fasta_filename = f"{fasta_dir}{library_name}_adapters.fasta"
    if not os.path.exists(fasta_filename):
        with open(fasta_filename, 'w') as fasta_file:
            fasta_file.write(fasta_content)
            print(f"Created: {fasta_filename}")
    else:
        print(f"Already exists: {fasta_filename}")
