import os
import pandas as pd
import glob

IDS = sample_data.index.values.tolist()
Assembler = config["Assembler"] 
sub = config["sub"]
	

#def check_ids():
#	files = glob.glob("output/gathered_assemblies/*.fasta")
#	for i in reversed(range(len(files))):
#		if os.path.exists("output/gathered_assemblies/gather.done"):
#			if os.path.getctime(files[i]) >= os.path.getctime("output/gathered_assemblies/gather.done"):
#				print(files[i]+" is NOT older than")
#				del(files[i])
#				continue
#			else:
#				print(files[i]+" is older than")
#		files[i] = os.path.basename(files[i]).split(".")[0]
##		print(id)
#	print("list from ids:"+str(files))
#	return files

#def check_sub():
#	files = glob.glob("output/gathered_assemblies/*.fasta")
#	for i in reversed(range(len(files))):
#		if os.path.exists("output/gathered_assemblies/gather.done"):
#			if os.path.getctime(files[i]) >= os.path.getctime("output/gathered_assemblies/gather.done"):
#				print(files[i]+" is NOT older than")
#				del(files[i])
#				continue
#		files[i] = os.path.basename(files[i]).split(".")[1]
#		print(id)
#	print("list from sub:"+str(files))
#	return files

#def check_assembler():
#	files = glob.glob("output/gathered_assemblies/*.fasta")
#	for i in reversed(range(len(files))):
#		if os.path.exists("output/gathered_assemblies/gather.done"):
#			if os.path.getctime(files[i]) >= os.path.getctime("output/gathered_assemblies/gather.done"):
#				print(files[i]+" is NOT older than")
#				del(files[i])
#				continue
#		files[i] = os.path.basename(files[i]).split(".")[2]
##		print(id)
#	print("list from assembler:"+str(files))
#	return files

#if os.environ["RUNMODE"] == "all" or os.environ["RUNMODE"] == "assembly":
#	IDS = sample_data.index.values.tolist()
#	Assembler = config["Assembler"] 
#	sub = config["sub"] 
#elif os.environ["RUNMODE"] == "annotate":
#	IDS = check_ids()
#	Assembler = check_assembler()
#	sub = check_sub()


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

##use this instead of expand to input all mitos.done files for annotation_stats rule

def pick_stats(wildcards):
    pull_list = []
    if os.environ["RUNMODE"] == "annotate":
        for f in glob.glob("output/gathered_assemblies/*.fasta"):
            (i,s,a) = os.path.basename(f).split(".")[:-1]
            pull_list.append("output/"+i+"/annotation/mitos/"+i+"."+s+"."+a+".mitos.done")
        #print("Mode is annotate: ", len(pull_list), "input files.")
        #for f in pull_list:
        #    print(f)
        return pull_list
    else:
        pull_list = []
        for i in IDS:
            for s in sub:
                for a in Assembler:
                    pull_list.append("output/"+i+"/annotation/mitos/"+i+"."+s+"."+a+".mitos.done")
        PULL_LIST = pull_list
        return PULL_LIST 

##use this instead of expand to input all second_mitos.done files for gene_positions rule

def pick_mitos2(wildcards):
    pull_list = []
    if os.environ["RUNMODE"] == "annotate":
        for f in glob.glob("output/gathered_assemblies/*.fasta"):
            (i,s,a) = os.path.basename(f).split(".")[:-1]
            pull_list.append("output/"+i+"/annotation/second_mitos/"+i+"."+s+"."+a+".second_mitos.done")
        #print("Mode is annotate: ", len(pull_list), "input files.")
        #for f in pull_list:
        #    print(f)
        return pull_list
    else:
        pull_list = []
        for i in IDS:
            for s in sub:
                for a in Assembler:
                    pull_list.append("output/"+i+"/annotation/second_mitos/"+i+"."+s+"."+a+".second_mitos.done")
        PULL_LIST = pull_list
        return PULL_LIST 

##use this as the driver to pick runmode from report rule

def pick_mode(wildcards):
    pull_list = []
    if os.environ["RUNMODE"] == "annotate":
        for f in glob.glob("output/gathered_assemblies/*.fasta"):
            (i,s,a) = os.path.basename(f).split(".")[:-1]
            pull_list.append("output/"+i+"/annotation/compare/CCT/"+i+"."+s+"."+a+".CCT.done")
        print("Mode is annotate: ", len(pull_list), "input files.")
        for f in pull_list:
            print(f)
        return pull_list
    elif os.environ["RUNMODE"] == "assembly":
        for i in IDS:
            for s in sub:
                for a in Assembler:    
                    pull_list.append("output/"+i+"/assemblies/"+s+"/"+a+"/"+a+".ok")
                    #pull_list.append("output/gathered_assemblies/"+i+"."+s+"."+a+".fasta")
        print("Mode is assembly: ", len(pull_list), "input files.")
        for f in pull_list:
            print(f)
        return pull_list
    else:
        pull_list = []
        #pull_list = ["output/{id}/annotation/compare/CCT/{id}.{sub}.{assembler}.CCT.done"]
        #pull_list = ["output/{id}/annotation/compare/CCT/{id}.{sub}.{assembler}.CCT.done".format(*i) for i in enumerate(IDS)] #, sub=sub, assembler=Assembler)]
        for i in IDS:
            #pull_list.append("output/"+i+"/annotation/compare/CCT/"+i+".{sub}.{assembler}.CCT.done")
            #print(pull_list)
            for s in sub:
                #pull_list.append("output/"+i+"/annotation/compare/CCT/"+i+"."+s+".{assembler}.CCT.done")
                #print(pull_list)
                for a in Assembler:
                    pull_list.append("output/"+i+"/annotation/compare/CCT/"+i+"."+s+"."+a+".CCT.done")
        #substring = "{"
        #PULL_LIST = [elem for elem in pull_list if substring not in elem]
        PULL_LIST = pull_list
		#print(pull_list)
        print(PULL_LIST)
        #for i in IDS:
        #    pull_list.format(id=IDS)
        print("Mode is all: ", len(PULL_LIST), "input files.")
        for f in PULL_LIST:
            print(f)
        return PULL_LIST 

