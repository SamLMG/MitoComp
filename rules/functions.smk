import os
import pandas as pd
import glob


def check_ids():
	files = glob.glob("output/gathered_assemblies/*.fasta")
	for i in reversed(range(len(files))):
		if os.path.exists("output/gathered_assemblies/gather.done"):
			if os.path.getctime(files[i]) >= os.path.getctime("output/gathered_assemblies/gather.done"):
				print(files[i]+" is NOT older than")
				del(files[i])
				continue
			else:
				print(files[i]+" is older than")
		files[i] = os.path.basename(files[i]).split(".")[0]
#		print(id)
	print("list from ids:"+str(files))
	return files

def check_sub():
	files = glob.glob("output/gathered_assemblies/*.fasta")
	for i in reversed(range(len(files))):
		if os.path.exists("output/gathered_assemblies/gather.done"):
			if os.path.getctime(files[i]) >= os.path.getctime("output/gathered_assemblies/gather.done"):
				print(files[i]+" is NOT older than")
				del(files[i])
				continue
		files[i] = os.path.basename(files[i]).split(".")[1]
#		print(id)
	print("list from sub:"+str(files))
	return files

def check_assembler():
	files = glob.glob("output/gathered_assemblies/*.fasta")
	for i in reversed(range(len(files))):
		if os.path.exists("output/gathered_assemblies/gather.done"):
			if os.path.getctime(files[i]) >= os.path.getctime("output/gathered_assemblies/gather.done"):
				print(files[i]+" is NOT older than")
				del(files[i])
				continue
		files[i] = os.path.basename(files[i]).split(".")[2]
#		print(id)
	print("list from assembler:"+str(files))
	return files

if os.environ["RUNMODE"] == "all" or os.environ["RUNMODE"] == "assembly":
	IDS = sample_data.index.values.tolist()
	Assembler = config["Assembler"] 
	sub = config["sub"] 
elif os.environ["RUNMODE"] == "annotate":
	IDS = check_ids()
	Assembler = check_assembler()
	sub = check_sub()


#IDS = sample_data.index.values.tolist()

#if os.environ["RUNMODE"] == "all":
#	IDS = sample_data.index.values.tolist()
#elif os.environ["RUNMODE"] == "annotate":
#	IDS = check_ids()

def get_accession(wildcards):
	return sample_data.loc[(wildcards.id), ["SRA"]].values[0]

def get_seed(wildcards):
	return sample_data.loc[(wildcards.id), ["seed"]].dropna().values[0]

def get_clade(wildcards):
        return sample_data.loc[(wildcards.id), ["Clade"]].dropna().values[0]

def get_code(wildcards):
        return sample_data.loc[(wildcards.id), ["Code"]].dropna().values[0]

def get_forward(wildcards):
	if len(sample_data.loc[(wildcards.id), ["forward"]].dropna()) == 0:
		return
	else:
		return sample_data.loc[(wildcards.id), ["forward"]].dropna().values[0]

def get_reverse(wildcards):
	if len(sample_data.loc[(wildcards.id), ["reverse"]].dropna()) == 0:
		return
	else:
		return sample_data.loc[(wildcards.id), ["reverse"]].dropna().values[0]

def get_kmer(wildcards):
	return sample_data.loc[(wildcards.id), ["novoplasty_kmer"]].dropna().values[0]

def get_readlength(wildcards):
        return sample_data.loc[(wildcards.id), ["Read_length"]].dropna().values[0]

def get_adapter(wildcards):
        return sample_data.loc[(wildcards.id), ["Adapter"]].dropna().values[0]

def get_type(wildcards):
        return sample_data.loc[(wildcards.id), ["Type"]].dropna().values[0]

def get_rounds(wildcards):
        return sample_data.loc[(wildcards.id), ["GO_Rounds"]].dropna().values[0]

def gather_assemblies(wildcards):
#	fasta_list = []
	return  glob.glob("output/gathered_assemblies/*.fasta")
	#for f in glob.glob("output/gathered_assemblies/*.fasta"):	
#		fasta_list.append(f)
	#return(fasta_list)
#	with open("output/gathered_assemblies/gathered_assemblies.txt", "w") as g:
#		g.write('\n'.join(fasta_list))
#	g.close()

	#for f in glob.glob("output/assemblies/" + wildcards.assembler + "/" + wildcards.id + "/" + wildcards.sub + "/"  + wildcards.id + "." + wildcards.assembler + "." + wildcards.sub + ".fasta")
	#print(fasta_list)

#def gather_assemblies(wildcards):
#	return glob.glob("output/assemblies/*/*/*/*.fasta")	

##return ["output/assemblies/" + wildcards.assembler + "/" + wildcards.id + "/" + wildcards.sub + "/" + wildcards.id + "." + wildcards.assembler + "." + wildcards.sub + ".fasta"]

