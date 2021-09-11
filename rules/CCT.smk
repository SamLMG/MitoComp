rule gbk_prep:
    input:
        rules.gene_positions.output
#        fasta = "compare/alignment/clustalo/{id}.{assembler}.{sub}.rolled.12476_RC.fasta",
#        gff = "compare/alignment/mitos2/{id}.{sub}.{assembler}/result.gff"
    output:
        "output/compare/CCT/{id}.{assembler}.{sub}.gbk.done"
    params:
        id = "{id}",
        assembler = "{assembler}",
        sub = "{sub}",
        gff = "output/compare/alignment/mitos2/{id}.{sub}.{assembler}/result.gff",
        gff_NoMFG = "output/assemblies/{assembler}/{id}/{sub}/annotation/result.gff",
        gbk = "output/compare/CCT/{id}.{assembler}.{sub}.genbank",
        outdir = "output/compare/alignment/mitos2/{id}.{sub}.{assembler}" 
#    resources:
#        qos="normal_0064",
#        partition="mem_0064",
#        mem="10G",
#        name="interleave",
#        nnode="-N 1"
    singularity: 
        "docker://pegi3s/emboss:6.6.0"
    shell:
        """
        if [ -f output/compare/alignment/clustalo/{params.id}.{params.assembler}.{params.sub}.rolled.*.fasta ]
        then
        seqret -sequence output/compare/alignment/clustalo/{params.id}.{params.assembler}.{params.sub}.rolled.*.fasta -outseq {params.gbk} -feature -fformat gff -fopenfile {params.gff} -osformat genbank -auto
        sed -i '1 a ACCESSION   {params.id}.{params.assembler}.{params.sub}' {params.gbk}
        sed -i 's/gene/CDS/g' {params.gbk}
        sed -i 's/*Name //g' {params.gbk}
        sed -i 's/([^()]*)//g' {params.gbk}
        sed -i '/*/d' {params.gbk}
        elif [ -f output/assemblies/{params.assembler}/{params.id}/{params.sub}/{params.id}.{params.assembler}.{params.sub}.fasta ]
        then 
        seqret -sequence output/assemblies/{params.assembler}/{params.id}/{params.sub}/{params.id}.{params.assembler}.{params.sub}.fasta -outseq {params.gbk} -feature -fformat gff -fopenfile {params.gff_NoMFG} -osformat genbank -auto
        sed -i '1 a ACCESSION   {params.id}.{params.assembler}.{params.sub}' {params.gbk}
        sed -i 's/gene/CDS/g' {params.gbk}
        sed -i 's/*Name //g' {params.gbk}
        sed -i 's/([^()]*)//g' {params.gbk}
        sed -i '/*/d' {params.gbk}
        #cp output/assemblies/{params.assembler}/{params.id}/{params.sub}/{params.id}.{params.assembler}.{params.sub}.fasta output/compare/alignment
        #sed -i 's#^>#output/compare/alignment/{params.id}.{params.assembler}.{params.sub}#g' output/compare/alignment/{params.id}.{params.assembler}.{params.sub}.fasta
        fi
        touch {output}
        """

#rule CGview:
#    input:
#        rules.gbk_prep.output
#    output:
#        "compare/CGview/{id}.{assembler}.{sub}.cgview.done"
#    params:
#        id = "{id}",
#        assembler = "{assembler}",
#        sub = "{sub}"
#    singularity:
#        "docker://pstothard/cgview:2.0.2"
#    shell:
#        """
#        perl /usr/bin/cgview_xml_builder.pl -sequence compare/CGview/{params.id}.{params.assembler}.{params.sub}.genbank -gc_content T -gc_skew T -size large-v2 -tick_density 0.05 -draw_divider_rings T -custom showBorder=false title="{params.id}.{params.assembler}.{params.sub} map" titleFontSize="200" -feature_labels T -output compare/CGview/{params.id}.{params.assembler}.{params.sub}.map.xml
#        java -jar /usr/bin/cgview.jar -i compare/CGview/{params.id}.{params.assembler}.{params.sub}.map.xml -o compare/CGview/{params.id}.{params.assembler}.{params.sub}.map.svg
#        touch {output}
#        """  


rule CCT:
    input:
        expand("output/compare/CCT/{{id}}.{assembler}.{sub}.gbk.done", id=IDS, sub=sub, assembler=Assembler),
        #rules.gbk_prep.output,
        #gbk =  "compare/CCT/{id}.{assembler}.{sub}.genbank" 
    output:
        "output/compare/CCT/{id}.{assembler}.{sub}.CCT.done"
    params:
        id = "{id}",
        assembler = "{assembler}",
        sub = "{sub}",
        outdir = "output/compare/CCT",
        wd = os.getcwd()
    singularity:
        "docker://pstothard/cgview_comparison_tool:1.0.1"
    shell:
        """
	set +o pipefail;
	#set +u;
        length=$(awk -F'\t' '{{if ($1 == "{params.assembler}" && $2 == "{params.id}" && $3 == "{params.sub}" && $4 > 1000){{print $4;}}}}' output/compare/Genes.txt)
        if [ -f output/compare/CCT/{params.id}.{params.assembler}.{params.sub}.genbank ] && [ $length > 1000 ]
        then
        	cd {params.outdir}
		build_blast_atlas.sh -i {params.id}.{params.assembler}.{params.sub}.genbank && returncode=$? || returncode=$? #> /dev/null 2>&1 
		echo $returncode
        	if [[ $returncode -eq 0 ]]
		then
			cp {params.id}*.genbank {params.id}.{params.assembler}.{params.sub}/comparison_genomes/
        		#build_blast_atlas.sh -p {params.id}.{params.assembler}.{params.sub}
        		
			build_blast_atlas.sh -p {params.id}.{params.assembler}.{params.sub} -z medium --custom "arrowheadLength=12 blast_divider_ruler=T blastRulerColor=green draw_divider_rings=T backboneColor=green global_label=T legend=T use_opacity=F backboneRadius=900 labelFontSize=60 borderColor=white width=3000 height=3000 gc_content=T backboneThickness=0.01 gcColorNeg=blue gcColorPos=red legendFontSize=30 featureThickness=50 _cct_blast_thickness=25.00000 useInnerLabels=false" && returncode=$? || returncode=$? #> /dev/null 2>&1
        		echo $returncode
			if [[ $returncode -eq 0 ]]
			then
        			redraw_maps.sh -p {params.id}.{params.assembler}.{params.sub} -f svg
			else
				echo "There was an Error in the second CCT command."
            			touch {params.wd}/{params.outdir}/{params.id}.{params.assembler}.{params.sub}.CCTmap.missing
			fi	
        	else
			echo "There was an Error in the first CCT command."
            		touch {params.wd}/{params.outdir}/{params.id}.{params.assembler}.{params.sub}.CCTmap.missing
		fi
	else
            touch {params.outdir}/{params.id}.{params.assembler}.{params.sub}.CCTmap.missing
        fi
        #if the expected final assembly exists, get a copy
        if [ -f {params.id}.{params.assembler}.{params.sub}/maps_for_dna_vs_dna/dna_vs_dna_medium.svg ]
        then
            cp {params.id}.{params.assembler}.{params.sub}/maps_for_dna_vs_dna/dna_vs_dna_medium.svg {params.id}.{params.assembler}.{params.sub}.map.svg 
            cp {params.id}.{params.assembler}.{params.sub}/maps_for_dna_vs_dna/dna_vs_dna_medium.png {params.id}.{params.assembler}.{params.sub}.map.png 
        else
            echo -e "\\n#### [$(date)]\\tCCT did not produce an assembly map. Either no assembly was found or it was under 1000bp" 
            touch {params.wd}/{params.outdir}/{params.id}.{params.assembler}.{params.sub}.CCTmap.missing
        fi
        #cd ../../
        touch {params.wd}/{output}
        """
