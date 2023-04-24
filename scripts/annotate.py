#!/usr/bin/env python
import pandas as pd
import sys
#read file containing paths
Bed_paths=sys.argv[1]
Assembly_paths=sys.argv[2]
Outfile=sys.argv[3]

Bed_paths = open(Bed_paths, "r")
#create list called assemblies and append each path
assemblies = []
for path in Bed_paths:
    path = path.strip("\n")
    assemblies.append(path)
Bed_paths.close() 

#open all bed files in assemblies list and extract a global list of genes  
global_gene_list = []
for assembly in assemblies:
    assembly_file = open(assembly, 'r') 
    LineNumber = 0
    for Line in assembly_file:
        # remove line ending
        Line = Line.strip('\n')
        # count up lines
        LineNumber = LineNumber + 1
        # split line
        ElementList = Line.split('\t')
        # genes are 4th element in df. Duplicated/split genes are shown with "_" and "-". These are removed with split()
        global_gene_list.append(ElementList[3].rstrip("()actg").split("-")[0].split("_")[0])
        # print(LineNumber, ':', gene_list)
    assembly_file.close()

#remove duplicate genes by converting list to set
global_gene_set = set(global_gene_list)

#print header line, convert global gene set to list, sort alphabetically and convert to strings separated by tab
species_genes_dictionary = {}
species_trnas_dictionary = {}
species_rrnas_dictionary = {}

output_list = []
for assembly in assemblies:
    assembly_file = open(assembly, 'r') 
    LineNumber = 0
    gene_list = []
    for Line in assembly_file:
        # remove line ending
        Line = Line.strip('\n')
        # count up lines
        LineNumber = LineNumber + 1
        # split line
        ElementList = Line.split('\t')
        # genes are 4th element in df
        gene_list.append(ElementList[3].rstrip("()actg").split("-")[0].split("_")[0])  ##.split()[0] keeps the element before the split character

#gene list as set - each gene only counted one time
#create dictionary of genes in gene_set where key is gene and value is count (#of times gene is found in annotation)
    gene_dict = {}

    for gene in global_gene_set:
        count = gene_list.count(gene)
        gene_dict[gene] = count
        
    gene_counts = ""
    for gene in sorted(gene_dict.keys()):
        gene_count = gene_dict[gene]
        gene_counts += "\t" + str(gene_count) #to check duplicated/split/absent gene names add " + "_" + gene "

#count total genes and total trnas for each sample - compare to max value for each species      
        
    found_genes = [] 
    found_trnas = []
    found_rrnas = []

    for gene in gene_dict.keys():
        if "trn" in gene:
            if gene_dict[gene] == 1:
                found_trnas.append(gene)
        elif "rrn" in gene:
            if gene_dict[gene] == 1:
                found_rrnas.append(gene)
        else:
            if gene_dict[gene] == 1:
                found_genes.append(gene)
    sp = assembly.split("/")[2]
    if sp in species_genes_dictionary.keys():
        if species_genes_dictionary[sp] < len(found_genes):
            species_genes_dictionary[sp] = len(found_genes)
    else:
        species_genes_dictionary[sp] = len(found_genes)
        
    if sp in species_trnas_dictionary.keys():
        if species_trnas_dictionary[sp] < len(found_trnas):
            species_trnas_dictionary[sp] = len(found_trnas)
    else:
        species_trnas_dictionary[sp] = len(found_trnas)

    if sp in species_rrnas_dictionary.keys():
        if species_rrnas_dictionary[sp] < len(found_rrnas):
            species_rrnas_dictionary[sp] = len(found_rrnas)
    else:
        species_rrnas_dictionary[sp] = len(found_rrnas)


#get seq length from fasta - remove newline character present in some assemblies
    with open (Assembly_paths, 'r') as assembly_paths:
        seq_length = 0
            for ap in assembly_paths:
                ap = ap.strip("\n")
                if assembly.split("/")[5] in ap:
                    fasta = open(ap, 'r')
                    for line in fasta:
                        if line.startswith(">"):
                            continue
                        else:
                            seq_length += len(line.strip("\n"))

    output_list.append(["\t".join(assembly.split("/")[5].split(".")), str(seq_length), str(len(found_genes)) + "/MAXGENECOUNT", str(len(found_rrnas)) + "/MAXRRNACOUNT", str(len(found_trnas)) + "/MAXTRNACOUNT", str(gene_counts).lstrip()])

Outfile_handle = open(Outfile, 'w')
print("Species", "Subsample", "Assembler", "Squence_length", "Genes", "rrnAs", "trnAs", "\t".join(sorted(list(global_gene_set))), sep='\t', file = Outfile_handle)
for outline in output_list:
    outline = "\t".join(outline)
    sp = outline.split("\t")[0] # this is the name of the species
    outline = outline.replace("MAXGENECOUNT", str(species_genes_dictionary[sp]))
    outline = outline.replace("MAXRRNACOUNT", str(species_rrnas_dictionary[sp]))    
    outline = outline.replace("MAXTRNACOUNT", str(species_trnas_dictionary[sp]))
    print(outline, file=Outfile_handle)
Outfile_handle.close()


