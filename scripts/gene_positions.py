#!/usr/bin/env python
import sys

#read file containing paths
paths=sys.argv[1] 
Genes=sys.argv[2]

#create list called assemblies and append the path to each bed file from the second annotation
assemblies = []
paths = open(paths, "r")

for path in paths:
        path = path.strip("\n")
        assemblies.append(path)
paths.close()
print("All paths:", assemblies)

#open Genes file to write header

header = "Species\tSubsample\tAssembler\tGenes\tStart\tEnd\n"
Genes = open(Genes, "w")
Genes.write(header)

for assembly in assemblies:
    bed_file = open(assembly, 'r')
    assembler = assembly.split("/")[5].split(".")[2]
    species = assembly.split("/")[5].split(".")[0]
    subsample = assembly.split("/")[5].split(".")[1]
    for line in bed_file:
        line = line.rstrip()
        first = line.split('\t')[0]
        gene = line.split('\t')[3].rstrip("()actg")
        orientation = line.split('\t')[5]
        gene_start = int()
        gene_end = int()
        if orientation == "+":
            gene_start = line.split('\t')[1]  # start of gene in second column
            gene_end = line.split('\t')[2]
        elif orientation == "-":
            gene_start = line.split('\t')[2]
            gene_start = int(gene_start) + 1 # - but if gene is reversed need to use end position plus 1
            gene_end = line.split('\t')[1]
                
        Genes.write(species + "\t" + subsample + "\t" + assembler + "\t" + gene + "\t" + str(gene_start) + "\t" + str(gene_end) + "\n")
Genes.close()
                
