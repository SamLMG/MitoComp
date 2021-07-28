rule report:
	input:
		mitos_done = expand("output/compare/alignment/mitos2/{id}.{sub}.{assembler}.mitos2.done", id=IDS, sub=sub, assembler=Assembler),
		cct_done = expand("output/compare/CCT/{id}.{assembler}.{sub}.CCT.done", id=IDS, sub=sub, assembler=Assembler),
		annotation_stats_done = "output/compare/annotation_stats.done" 
	output:
		report = "output/compare/report/report.html"
	params:
		wd = os.getcwd()
	singularity:
		"docker://reslp/rmarkdown:4.0.3"
	shell:
		"""	
		# gather bedfiles
		# bedfiles all have the same name, therfore this hack to find, rename and copy the files to a location in the report directory.
#		mkdir -p report/bedfiles
#		for bedfile in $(find ./compare/alignment/mitos2/ -name "result.bed"); do
#			name=$(dirname $(echo $bedfile | sed -e 's#^\./compare/alignment/mitos2/##'))
#			cp $bedfile report/bedfiles/$name.bed
#		done
	
		# gather assemblies
#		assemblies=$(find ./assemblies/*/*/*/*.fasta)
#		mkdir -p report/assemblies
#		cp $assemblies report/assemblies 2>/dev/null || :
	
		# gather maps	
		maps=$(find ./output/compare/CCT/*.png)
		mkdir -p output/compare/report/maps
		cp $maps output/compare/report/maps 2>/dev/null || :
		
		# copy genes file
		cp output/compare/Genes.txt output/compare/report/Genes.txt
		
		# create report
		Rscript -e 'rmarkdown::render("./scripts/report.Rmd")'

		# clean up
		mv scripts/report.html output/compare/report/report.html
		tar -pcf {params.wd}/report.tar -C {params.wd} report
		"""	
