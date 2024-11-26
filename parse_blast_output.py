import os
import pandas as pd

blast_output_dir = "/global/scratch/projects/fc_wolflab/bbioinfo/sarrah/tb/96_tb_samples/blast_results"
op_dir = "/global/scratch/projects/fc_wolflab/bbioinfo/sarrah/tb/96_tb_samples/blast_df"

metadata_df = pd.read_csv('new_96_samples.csv')

metadata_dict = metadata_df.set_index('Sample_name').to_dict(orient='index')

files = os.listdir(blast_output_dir)

df_list = []

for file in files:
    parts = file.split('_')
    sample_name = parts[0] + '_' + parts[1]
    direction = 'forward' if parts[3] == '1' else 'reverse'

    sample_meta = metadata_dict.get(int(parts[1]), {})
    library_name = sample_meta.get('Library_name', 'N/A')
    total_reads = sample_meta.get('Total reads', 'N/A')
    analyze = sample_meta.get('Analyze', 'N/A')
    tb_class = sample_meta.get('TB_class', 'Unknown')

    file_path = os.path.join(blast_output_dir, file)
    if os.stat(file_path).st_size == 0:  
        df = pd.DataFrame([['N/A'] * 9], 
                          columns=['qseqid', 'length', 'qcovs', 'qcovhsp', 'evalue', 
                                   'bitscore', 'pident', 'sscinames', 'salltitles'])
    else:
        df = pd.read_csv(file_path, sep='\t', header=None)
        column_count = df.shape[1]
        if column_count == 9:
            df.columns = ['qseqid', 'length', 'qcovs', 'qcovhsp', 'evalue', 
                          'bitscore', 'pident', 'sscinames', 'salltitles']
        elif column_count == 8:
            df.columns = ['qseqid', 'length', 'qcovs', 'evalue', 'bitscore', 
                          'pident', 'sscinames', 'salltitles']
        else:
            raise ValueError(f"too many columns: {column_count}")

    df['Sample'] = sample_name
    df['Direction'] = direction
    df['Library_name'] = library_name
    df['Total_reads'] = total_reads
    df['Analyze'] = analyze
    df['TB_class'] = tb_class

    df = df[['Sample', 'Direction', 'Library_name', 'Total_reads', 'Analyze', 'TB_class'] 
            + df.columns[:-6].tolist()]

    output_file = os.path.join(op_dir, f"{sample_name}_{direction}.csv")
    df.to_csv(output_file, index=False)

    df_list.append(df)

concatenated_df = pd.concat(df_list, ignore_index=True)

concatenated_output = '/global/scratch/projects/fc_wolflab/bbioinfo/sarrah/tb/96_tb_samples/concatenated_results.csv'
concatenated_df.to_csv(concatenated_output, index=False)

print(f"concatenated  df path  {concatenated_output}")
print(f"df shape: {concatenated_df.shape}")
