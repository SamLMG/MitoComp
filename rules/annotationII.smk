rule second_mitos:
    input:
        rules.align.output,
    output:
        "output/compare/alignment/mitos2/{id}.{sub}.{assembler}.mitos2.done"
    params:
        id = "{id}",
        assembler = "{assembler}",
        genetic_code = get_code,
        sub = "{sub}",
        outdir = "output/compare/alignment/mitos2/{id}.{sub}.{assembler}"
    log:
        stdout = "output/compare/alignment/mitos2/{id}.{sub}.{assembler}/stdout.txt",
        stderr = "output/compare/alignment/mitos2/{id}.{sub}.{assembler}/stderr.txt"
    singularity:
        "docker://reslp/mitos:1.0.5"
    threads: config["threads"]["annotation"]
    shell:
        """
        if [[ ! -d {params.outdir} ]]; then mkdir {params.outdir}; fi
        if [[ $(find output/compare/alignment/clustalo/{params.id}.{params.assembler}.{params.sub}.rolled.*.fasta) != "" ]]; then
            nfiles=$(find output/compare/alignment/clustalo/{params.id}.{params.assembler}.{params.sub}.rolled.*.fasta | wc -l)
            if [[ $nfiles -gt 1 ]]; then
                echo "Mitos could not be run, there are multiple files to run it on. Please check manually."
                touch {output}
                exit 0
            else
                runmitos.py -i output/compare/alignment/clustalo/{params.id}.{params.assembler}.{params.sub}.rolled.*.fasta -o {params.outdir} -r dbs/mitos/mitos1-refdata -c {params.genetic_code}
                # copy new bed files to report directory with informative name
                #mkdir -p output/compare/report/bedfiles
                #cp output/compare/alignment/mitos2/{params.id}.{params.sub}.{params.assembler}/result.bed output/compare/report/bedfiles/{params.id}.{params.sub}.{params.assembler}.bed 
                # copy rolled + RC assemblies to report directory
                #mkdir -p output/compare/report/assemblies
                #cp output/compare/alignment/clustalo/{params.id}.{params.assembler}.{params.sub}*.fasta output/compare/report/assemblies/{params.id}.{params.assembler}.{params.sub}.fasta
                cp output/compare/alignment/clustalo/{params.id}.{params.assembler}.{params.sub}.rolled.*.fasta output/compare/alignment/{params.id}.{params.assembler}.{params.sub}.final.fasta
                fi
        else
        echo "Mitos could not be run because the input file is missing. Maybe the assembler did not produce output?" >> {log.stderr}
        fi
        if [[ $(find output/assemblies/{params.assembler}/{params.id}/{params.sub}/annotation/result.bed) != "" ]]; then cp output/assemblies/{params.assembler}/{params.id}/{params.sub}/annotation/result.bed {params.outdir}/result.bed
        awk '{{$1= "output/compare/alignment/mitos2/{params.id}.{params.assembler}.{params.sub}"; print $0}}' output/compare/alignment/mitos2/{params.id}.{params.sub}.{params.assembler}/result.bed > output/compare/alignment/mitos2/{params.id}.{params.sub}.{params.assembler}/tmp && mv output/compare/alignment/mitos2/{params.id}.{params.sub}.{params.assembler}/tmp output/compare/alignment/mitos2/{params.id}.{params.sub}.{params.assembler}/result.bed
        sed -i 's/ /\t/g' output/compare/alignment/mitos2/{params.id}.{params.sub}.{params.assembler}/result.bed 
        cp output/assemblies/{params.assembler}/{params.id}/{params.sub}/{params.id}.{params.assembler}.{params.sub}.fasta output/compare/alignment/{params.id}.{params.assembler}.{params.sub}.final.fasta
        sed -i 's#^>#output/compare/alignment/{params.id}.{params.assembler}.{params.sub}#g' output/compare/alignment/{params.id}.{params.assembler}.{params.sub}.final.fasta
        #mkdir -p output/compare/report/bedfiles
        #cp output/compare/alignment/mitos2/{params.id}.{params.sub}.{params.assembler}/result.bed output/compare/report/bedfiles/{params.id}.{params.sub}.{params.assembler}.bed
        #mkdir -p output/compare/report/assemblies
        #cp output/assemblies/{params.assembler}/{params.id}/{params.sub}/{params.id}.{params.assembler}.{params.sub}.fasta output/compare/report/assemblies/{params.id}.{params.assembler}.{params.sub}.fasta
        fi
        touch {output}
        """

rule gene_positions:
    input:
        #rules.second_mitos.output
        expand(rules.second_mitos.output, id=IDS, sub=sub, assembler=Assembler) 
        #"compare/alignment/mitos2/mitos2_paths.txt"
    output:
        "output/compare/alignment/mitos2/gene_positions.done"
        #positions = "compare/alignment/mitos2/Gene_positions.txt"
    shell:
        """
        find ./output/compare/alignment/mitos2/ -name "result.bed" | cat > output/compare/alignment/mitos2/mitos2_paths.txt        
        #cat output/compare/No_MFG_assemblies.txt >> output/compare/alignment/mitos2/mitos2_paths.txt  #include original annotations for those assemblies with no 'most found gene'
        scripts/gene_positions.py output/compare/alignment/mitos2/mitos2_paths.txt output/compare/alignment/mitos2/Gene_positions.txt
        touch {output}
        """
