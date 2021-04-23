#!/usr/bin/env python
import pandas as pd
#read file containing paths
paths = open("paths.txt", "r")
#create list called assemblies and append each path
assemblies = []
for path in paths:
	path = path.strip("\n")
	assemblies.append(path)
paths.close() 
print("All paths:", assemblies)

#open all bed files in assemblies list and extract a global list of genes  
#x = 0 
Genes = open("compare/Genes.txt", 'w')
global_gene_list = []
for assembly in assemblies:
	assembly_file = open(assembly, 'r') 
#	x += 1
	Line = assembly_file.readline()
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
print("Assembler", "Species", "Subsample", "\t".join(sorted(list(global_gene_set))), sep='\t', file = Genes)
for assembly in assemblies:
	assembly_file = open(assembly, 'r') 
#	x += 1
	Line = assembly_file.readline()
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
		if count == 0:    #if gene not found print to screen
			print(gene, count)
		if count > 1:     #if gene split/duplicated print to screen
			print(gene, count)
#df = pd.DataFrame(gene_dict, assemblies)
#print(df)

#with open("Genes.txt", 'w') as Genes: 
	gene_counts = ""
	for gene in sorted(gene_dict.keys()):
		gene_count = gene_dict[gene]
		gene_counts += "\t" + str(gene_count) #to check duplicated/split/absent gene names add " + "_" + gene "
	print('\t'.join(assembly.split("/")[2:5]), gene_counts, sep='\t', file = Genes) #prints assembly with path split into three columns and gene counts to file 
Genes.close()

print(global_gene_set)

##find gene/genes represented once only in most assemblies (i.e. least often missing or duplicated/split)

#gene_found = {}

#File = open("Genes.txt", "r")
#for gene in global_gene_set:
#	for assembly in File:
#		count = 0
#		gene_found[gene] = count
#		if gene in assembly == 1:
#			count += 1
#		else:
#			continue
#print(gene_found)
gene_found = {}
Genes = pd.read_table("compare/Genes.txt", sep = '\t')
gene_list = list(Genes.columns)
del gene_list[0:3]
print(gene_list)
#for gene in gene_list:
	#count = Genes.query(gene = '1')[gene].sum()
count = Genes[Genes == 1].sum(axis = 0)
gene_found[gene] = count
#Genes.close
print(gene_found)
#most_found_gene = max(gene_found)
most_found_gene = max(gene_found, key = gene_found.get)
print(most_found_gene)

#search in bed files for line containing most_found_gene
starts_dict = {}
rev_starts_dict = {}
forward_assemblies = []
reverse_assemblies = []
for assembly in assemblies:	
	line_number = 0
	#list_of_results = []
	with open(assembly, 'r') as bed:
		for line in bed:
			line_number += 1
			if most_found_gene in line:
				#gene_starts = line.split('\t')[1] #start of gene in second column - but if gene is reversed need to use end position plus 1 
				#gene_starts.split('/')[2:5]
				#starts_dict[assembly] = gene_starts
				#gene_ends = line.split('\t')[2]
				#gene_ends = gene_ends + 1
				#check orientation - from -/+ in end column
				orientation = line.split('\t')[5]
				#print(orientation)
				if "+" in orientation: 
					gene_starts = line.split('\t')[1] #start of gene in second column - but if gene is reversed need to use end position plus 1 
					#gene_starts.split('/')[2:5]
					starts_dict[assembly] = gene_starts
					forward_assemblies.append(assembly)
				if "-" in orientation:
					gene_starts = line.split('\t')[2]
					gene_starts = int(gene_starts) + 1
					#gene_starts.split('/')[2:5]
					starts_dict[assembly] = gene_starts
					#print(assembly)
					rev_starts_dict[assembly] = gene_starts
					reverse_assemblies.append(assembly)
print("Reverse:", reverse_assemblies)
print("Forward:", forward_assemblies)				
				#list_of_results.append((assembly.split('/')[2:5], f"Start position of {most_found_gene} is: {gene_start}"))
print("starts", starts_dict)
print("rev_stats", rev_starts_dict)
#print('\t'.join(assembly.split("/")[2:5]), gene_start, sep='\t')#, file = Genes)
#print(list_of_results)


# write to outfile
with open("compare/start_positions.txt", 'w') as starts:
	#gene_starts = ""
	for assembly in starts_dict.keys():
		gene_start = starts_dict[assembly]
		#gene_starts += "\t" +str(gene_start)
		#path = str(assembly.split("/")[1:5],"/", assembly.split("/")[3])#".", assembly.split("/")[2],".", assembly.split("/")[4],".", "fasta"
		#path += '/'.join(assembly)
		#print(path, gene_start, sep='', file = starts)  
		print('/'.join(assembly.split("/")[1:5]),"/", assembly.split("/")[3],".", assembly.split("/")[2],".", assembly.split("/")[4],".", "fasta	", gene_start, sep='', file = starts)
starts.close()

#print list of files that need to be reverse complement 
i = 0
with open("compare/RC_assemblies.txt", 'w') as RC:
	#rev_starts_dict = ""
	for rev in reverse_assemblies:
		i += 1
		rev_gene_start = rev_starts_dict[rev]
		#rev_gene_starts += "\t" + str(rev_gene_start)
		print("compare/alignment/", rev.split("/")[3],".", rev.split("/")[2], ".", rev.split("/")[4], ".rolled.", rev_gene_start, ".fasta", sep = '', file = RC)
RC.close()

#print list of files already in forward sense
j = 0
with open("compare/forward_assemblies.txt", 'w') as FA:
	for a in forward_assemblies:
		i += 1
		gene_start = starts_dict[a]
		print("compare/alignment/", a.split("/")[3],".", a.split("/")[2], ".", a.split("/")[4], ".rolled.", gene_start, ".fasta", sep = '', file = FA)
FA.close()

