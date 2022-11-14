
#rule report:
#	input:
#		#mitos_done = expand("output/{id}/annotation/second_mitos/{id}.{sub}.{assembler}.second_mitos.done", id=IDS, sub=sub, assembler=Assembler),
#		cct_done = expand("output/{id}/annotation/compare/CCT/{id}.{sub}.{assembler}.CCT.done", id=IDS, sub=sub, assembler=Assembler),
#		annotation_stats_done = "output/stats/annotation_stats.done" 
#	output:
#		report = "output/report/report.html"
#	params:
#		#id = "{id}",
#		#assembler = "{assembler}",
#		#sub = "{sub}",
#		wd = os.getcwd()
#	singularity:
#		"docker://reslp/rmarkdown:4.0.3"
#	shell:
#		"""	
#		# gather bedfiles
#		# bedfiles all have the same name, therfore this hack to find, rename and copy the files to a location in the report directory.
#		mkdir -p output/report/bedfiles
#		for bedfile in $(find ./output/*/annotation/second_mitos/*/ -name "result.bed"); do
#			name=$(echo $bedfile | awk -F/ '{{print $6}}')
#			cp $bedfile output/report/bedfiles/$name.bed
#		done
#	
#		# gather assemblies
#		assemblies=$(find ./output/*/annotation/alignment/*.final.fasta)
#		mkdir -p output/report/assemblies
#		cp $assemblies output/report/assemblies 2>/dev/null || :
#                #sed -i 's/.final//g' output/report/assemblies/*
#                #mv output/compare/report/assemblies/*.final.fasta mv output/compare/report/assemblies/*.fasta
#
#		# gather maps	
#		maps=$(find ./output/*/annotation/compare/CCT/*.png)
#		mkdir -p output/report/maps
#		cp $maps output/report/maps 2>/dev/null || :
#		
#		# copy genes file
#		cp output/stats/Genes.txt output/report/Genes.txt
#		
#		# create report
#		Rscript -e 'rmarkdown::render("./scripts/report.Rmd")'
#
#		# clean up
#		mv scripts/report.html output/report/report.html
#		tar -pcf {params.wd}/output/report.tar -C {params.wd}/output/ report
#		"""

#def decide_cct():
#	files = glob.glob("output/gathered_assemblies/*.fasta")
#	for i in range(len(files)):
#		(id,sub,assembler) = os.path.basename(files[i]).split(".")[:-1]
#		print(id,sub,assembler)
		#files[i] = "output/"+id+"/annotation/compare/CCT/"+id+"."+sub+"."+assembler+".CCT.done"
#	files = ["output/C_spec/annotation/compare/CCT/C_spec.5000000.mitobim.CCT.done"]
#	return files

IDS = sample_data.index.values.tolist()
Assembler = config["Assembler"] 
sub = config["sub"]
	
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
    else:
        pull_list = []
        #pull_list = ["output/{id}/annotation/compare/CCT/{id}.{sub}.{assembler}.CCT.done"]
        #pull_list = ["output/{id}/annotation/compare/CCT/{id}.{sub}.{assembler}.CCT.done".format(*i) for i in enumerate(IDS)] #, sub=sub, assembler=Assembler)]
        for i in IDS:
            pull_list.append("output/"+i+"/annotation/compare/CCT/"+i+".{sub}.{assembler}.CCT.done")
            print(pull_list)
            for s in sub:
                pull_list.append("output/"+i+"/annotation/compare/CCT/"+i+"."+s+".{assembler}.CCT.done")
                print(pull_list)
                for a in Assembler:
                    pull_list.append("output/"+i+"/annotation/compare/CCT/"+i+"."+s+"."+a+".CCT.done")
        substring = "{"
        PULL_LIST = [elem for elem in pull_list if substring not in elem]
        #print(pull_list)
        print(PULL_LIST)
        #for i in IDS:
        #    pull_list.format(id=IDS)
        print("Mode is all: ", len(PULL_LIST), "input files.")
        for f in PULL_LIST:
            print(f)
        return PULL_LIST 



#if os.environ["RUNMODE"] == "all" or os.environ["RUNMODE"] == "assembly":
rule report:
    input:
        pick_mode
#			#mitos_done = expand("output/{id}/annotation/second_mitos/{id}.{sub}.{assembler}.second_mitos.done", id=IDS, sub=sub, assembler=Assembler),
###			#cct_done = expand("output/{id}/annotation/compare/CCT/{id}.{sub}.{assembler}.CCT.done", id=IDS, sub=sub, assembler=Assembler),
#			#annotation_stats_done = "output/stats/annotation_stats.done" 
    output:
        "output/report/report.html"
    params:
        wd = os.getcwd()
    singularity:
        "docker://reslp/rmarkdown:4.0.3"
    shell:
        """	
        # gather bedfiles
        # bedfiles all have the same name, therfore this hack to find, rename and copy the files to a location in the report directory.
        mkdir -p output/report/bedfiles
        for bedfile in $(find ./output/*/annotation/second_mitos/*/ -name "result.bed"); do
            name=$(echo $bedfile | awk -F/ '{{print $6}}')
            cp $bedfile output/report/bedfiles/$name.bed
        done
	
        # gather assemblies
        assemblies=$(find ./output/*/annotation/alignment/*.final.fasta)
        mkdir -p output/report/assemblies
        cp $assemblies output/report/assemblies 2>/dev/null || :
        while read first rest
            file=$first
            position=$rest
            prefix1=$(echo $first | cut -d "/" -f3 | cut -d "." -f 1)
            prefix2=$(echo $first | cut -d "/" -f3 | cut -d "." -f 1-3)
        do
        echo $prefix2
        if [ ! -z "$prefix2" ]
        then
            sed -i "s#>.*#>$prefix2#g" output/report/assemblies/$prefix2.final.fasta
        else
            echo $prefix2
            break 
        fi
        done < output/stats/start_positions.txt
        #sed -i 's/.final//g' output/report/assemblies/*
        #mv output/compare/report/assemblies/*.final.fasta mv output/compare/report/assemblies/*.fasta
	
        # gather maps	
        maps=$(find ./output/*/annotation/compare/CCT/*.png)
        mkdir -p output/report/maps
        cp $maps output/report/maps 2>/dev/null || :
		
        # copy genes file
        cp output/stats/Genes.txt output/report/Genes.txt
			
        # create report
        Rscript -e 'rmarkdown::render("./scripts/report.Rmd")'
	
        # clean up
        mv scripts/report.html output/report/report.html
        tar -pcf {params.wd}/output/report.tar -C {params.wd}/output/ report
        """	
#elif os.environ["RUNMODE"] == "annotate":
#	rule report:
#		input:
#			cct_done = expand("output/{id}/annotation/compare/CCT/{id}.{sub}.{assembler}.CCT.done", zip, id=IDS, sub=sub, assembler=Assembler),
#			#annotation_stats_done = "output/stats/annotation_stats.done" 
#		output:
#			report = "output/report/report.html"
#		params:
#			#id = "{id}",
#			#assembler = "{assembler}",
#			#sub = "{sub}",
#			wd = os.getcwd()
#		singularity:
#			"docker://reslp/rmarkdown:4.0.3"
#		shell:
#			"""	
#			# gather bedfiles
#			# bedfiles all have the same name, therfore this hack to find, rename and copy the files to a location in the report directory.
#			mkdir -p output/report/bedfiles
#			for bedfile in $(find ./output/*/annotation/second_mitos/*/ -name "result.bed"); do
#				name=$(echo $bedfile | awk -F/ '{{print $6}}')
#				cp $bedfile output/report/bedfiles/$name.bed
#			done
#		
#			# gather assemblies
#			assemblies=$(find ./output/*/annotation/alignment/*.final.fasta)
#			mkdir -p output/report/assemblies
#			cp $assemblies output/report/assemblies 2>/dev/null || :
#			#sed -i 's/.final//g' output/report/assemblies/*
#                	#mv output/compare/report/assemblies/*.final.fasta mv output/compare/report/assemblies/*.fasta
#	
#			# gather maps	
#			maps=$(find ./output/*/annotation/compare/CCT/*.png)
##			mkdir -p output/report/maps
#			cp $maps output/report/maps 2>/dev/null || :
#			
#			# copy genes file
#			cp output/stats/Genes.txt output/report/Genes.txt
#			
#			# create report
#			Rscript -e 'rmarkdown::render("./scripts/report.Rmd")'
#	
#			# clean up
#			mv scripts/report.html output/report/report.html
#			tar -pcf {params.wd}/output/report.tar -C {params.wd}/output/ report
###			"""	
