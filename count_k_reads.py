import os

base_dir = "/global/scratch/projects/fc_wolflab/bbioinfo/sarrah/tb/96_tb_samples"

results = []

for sample in os.listdir(base_dir):
    sample_path = os.path.join(base_dir, sample)
    
    if os.path.isdir(sample_path):
        tb1_file = os.path.join(sample_path, f"{sample}_TB_1.fasta")
        tb2_file = os.path.join(sample_path, f"{sample}_TB_2.fasta")
        
        tb1_count = tb2_count = 0
        
        if os.path.exists(tb1_file):
            with open(tb1_file) as f:
                tb1_count = sum(1 for line in f if line.startswith(">"))

        if os.path.exists(tb2_file):
            with open(tb2_file) as f:
                tb2_count = sum(1 for line in f if line.startswith(">"))

        total_reads = tb1_count + tb2_count
        results.append((sample, tb1_count, tb2_count, total_reads))

print("Sample\tTB_1_Reads\tTB_2_Reads\tTotal_Reads")
for sample, tb1, tb2, total in results:
    print(f"{sample}\t{tb1}\t{tb2}\t{total}")
