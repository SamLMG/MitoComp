#!/usr/bin/env python
import sys
import os
import shutil

def rev_comp(seq):
        complements = {'A':'T','T':'A','G':'C','C':'G','K':'N','M':'N','R':'N','Y':'N','S':'N','W':'N','B':'N','V':'N','H':'N','D':'N','X':'N','N':'N'}
        seq = seq.strip()
        if seq.startswith('>'):
            header = seq
            return(header)
        else:
       	    nucs = "".join(complements.get(nucs, nucs) for nucs in seq)[::-1]
            RCseq = nucs.upper()
            return(RCseq)


with open("compare/RC_assemblies.txt", 'r') as RC_file:
        for line in RC_file:
                fasta = line.rstrip()
                fasta_prefix = '.'.join(fasta.split(".")[0:5])
                print("Working on file:", fasta, file=sys.stderr)
                with open(fasta, 'r') as fasta_file:
                        for seq in fasta_file:
                                print(rev_comp(seq))
                                with open(f"{fasta_prefix}_RC.fasta", 'a') as out_file:
                                    print(rev_comp(seq), file=out_file)
                                out_file.close()
        #for fasta in RC_file:

with open("compare/forward_assemblies.txt", 'r') as FA_file:
	for LINE in FA_file:
		ffasta = LINE.rstrip()
		dest_ffasta = ffasta.split("/")[2]
		shutil.copy(ffasta, f"compare/alignment/clustalo/{dest_ffasta}")
FA_file.close()
