#!/usr/bin/env python
import pandas as pd
import sys

Genes=sys.argv[1]
Bed_paths=sys.argv[2]
MFG=sys.argv[3]
No_MFG=sys.argv[4]
Start_pos=sys.argv[5]
Reverse=sys.argv[6]
Forward=sys.argv[7]
#read summary file of annotations in order to select gene most commonly occuring across assemblies - this will be used as the start position in the "roll" rule

gene_found = {}

Genes_handle = pd.read_table(Genes, sep = '\t')
gene_list = list(Genes_handle.columns)
del gene_list[0:7]
print(gene_list)
for gene in gene_list:
        count = Genes_handle[gene].to_list()
        count1 = [item for item in count if item == 1] #count only genes that are found once per assembly 
        list_length = len(count1) #in how many assemblies are these genes found
        print(gene, list_length)
        gene_found[gene] = list_length



print("gene_found", gene_found)
most_found_gene = max(gene_found, key = gene_found.get) #which gene is found (unsplit and unduplicated) in the most assemblies - N.B. this may result in a "tie" in which case the first alphabetically will be selected
print("most found gene", most_found_gene)


#create list called assemblies and append each path

paths_handle = open(Bed_paths, "r")
assemblies = []
for path in paths_handle:
        path = path.strip("\n")
        assemblies.append(path)
paths_handle.close() 
print("All paths:", assemblies)

#make list of assemblies in which the 'most found gene' IS and IS NOT found - print these paths to a .txt file
MFG_assemblies = []
for assembly in assemblies:
        line_number = 0
        with open(assembly, 'r') as bed:
                for line in bed:
                        line_number += 1
                        if most_found_gene in line:
                                print("most found gene present in", assembly)
                                MFG_assemblies.append(assembly)
with open(MFG, 'w') as mfg:
        print('\n'.join(MFG_assemblies), file = mfg)
mfg.close               

No_MFG_assemblies = []
for assembly in assemblies:
        if assembly not in MFG_assemblies:
                No_MFG_assemblies.append(assembly)
                print("most found gene NOT present in", assembly)

with open(No_MFG, 'w') as no_mfg:
        print('\n'.join(No_MFG_assemblies), file = no_mfg)
no_mfg.close

#search in bed files to determine which assemblies must be put into reverse complement
starts_dict = {}
rev_starts_dict = {}
forward_assemblies = []
reverse_assemblies = []
for assembly in assemblies:     
        line_number = 0
        with open(assembly, 'r') as bed:
                for line in bed:
                        line_number += 1
                        if most_found_gene in line:
                                orientation = line.split('\t')[5]
                                if "+" in orientation: 
                                        gene_starts = line.split('\t')[1] #start of gene in second column - but if gene is reversed need to use end position plus 1 
                                        starts_dict[assembly] = gene_starts
                                        forward_assemblies.append(assembly)
                                if "-" in orientation:
                                        gene_starts = line.split('\t')[2]
                                        gene_starts = int(gene_starts) + 1
                                        starts_dict[assembly] = gene_starts
                                        rev_starts_dict[assembly] = gene_starts
                                        reverse_assemblies.append(assembly)
print("Reverse:", reverse_assemblies)
print("Forward:", forward_assemblies)                           
print("starts", starts_dict)
print("rev_stats", rev_starts_dict)

# write start positions to file
with open(Start_pos, 'w') as starts:
        for assembly in starts_dict.keys():
                gene_start = starts_dict[assembly]
                print("output/gathered_assemblies/", assembly.split("/")[5],".", "fasta", '\t', gene_start, sep='', file = starts)
starts.close()

#print list of files that need to be reverse complement 
i = 0
with open(Reverse, 'w') as RC:
        for rev in reverse_assemblies:
                i += 1
                rev_gene_start = rev_starts_dict[rev]
                print("output/", rev.split("/")[2], "/annotation/", "alignment/", rev.split("/")[5], ".rolled.", rev_gene_start, ".fasta", sep = '', file = RC)
RC.close()

#print list of files already in forward sense
j = 0
with open(Forward, 'w') as FA:
        for a in forward_assemblies:
                i += 1
                gene_start = starts_dict[a]
                print("output/", a.split("/")[2], "/annotation/", "alignment/", a.split("/")[5], ".rolled.", gene_start, ".fasta", sep = '', file = FA)
FA.close()




