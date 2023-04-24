#!/usr/bin/env python
import sys
import os
import shutil

arguments = sys.argv
sampleid = arguments[1]

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


with open("output/stats/RC_assemblies.txt", 'r') as RC_file:
        for line in RC_file:
                if sampleid not in line:
                      print(sampleid, "was not found in line of RC assemblies. Will skip this line")
                      continue
                fasta = line.rstrip()
                fasta_prefix = '.'.join(fasta.split(".")[0:5])
                print("Working on file:", fasta, file=sys.stderr)
                with open(fasta, 'r') as fasta_file:
                        with open(f"{fasta_prefix}_RC.fasta", 'w') as out_file:
                               for seq in fasta_file:
                                    print(rev_comp(seq), file=out_file)

with open("output/stats/forward_assemblies.txt", 'r') as FA_file:
        for fline in FA_file:
                if sampleid not in fline:
                      print(sampleid, "was not found in line of forward assemblies. Will skip this line")
                      continue
                ffasta = fline.rstrip()
                dest_ffasta = ffasta.split("/")[4]
                x = ("output", ffasta.split("/")[1], "annotation/alignment/clustalo")
                dest_dir = '/'.join(x)
                shutil.copy(ffasta, f"{dest_dir}/{dest_ffasta}")
