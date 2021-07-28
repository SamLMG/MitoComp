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

header = "Assembler\tSpecies\tSubsample\tGenes\tStart\tEnd\n"
Genes = open(Genes, "w")
Genes.write(header)


#with open("compare/alignment/mitos2/D_rerio.5000000.mitoflex/result.bed", 'r') as bed:
#	for line in bed:
#		line = line.rstrip()
#		assembler = line.split("\t")[]


for assembly in assemblies:
		bed_file = open(assembly, 'r')
		for line in bed_file:
			line = line.rstrip()
			first = line.split('\t')[0]
			
			assembler = first.split(".")[1]
			species = first.split('.')[0].split("/")[2]
			subsample = first.split(".")[2].split("_")[0]
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
		
			Genes.write(assembler + "\t" + species + "\t" + subsample + "\t" + gene + "\t" + str(gene_start) + "\t" + str(gene_end) + "\n")
Genes.close()
		
