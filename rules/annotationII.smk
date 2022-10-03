rule second_mitos:
    input:
        rules.align.output,
    output:
        "output/{id}/annotation/second_mitos/{id}.{sub}.{assembler}.second_mitos.done"
    params:
        id = "{id}",
        assembler = "{assembler}",
        genetic_code = get_code,
        sub = "{sub}",
        outdir = "output/{id}/annotation/second_mitos/{id}.{sub}.{assembler}"
    log:
        stdout = "output/{id}/annotation/second_mitos/{id}.{sub}.{assembler}/stdout.txt",
        stderr = "output/{id}/annotation/second_mitos/{id}.{sub}.{assembler}/stderr.txt"
    singularity:
        "docker://reslp/mitos:1.0.5"
    threads: config["threads"]["annotation"]
    shell:
        """
        if [[ ! -d {params.outdir} ]]; then mkdir {params.outdir}; fi
        if [[ $(find output/{params.id}/annotation/alignment/clustalo/{params.id}.{params.sub}.{params.assembler}.rolled.*.fasta) != "" ]]; then
            nfiles=$(find output/{params.id}/annotation/alignment/clustalo/{params.id}.{params.sub}.{params.assembler}.rolled.*.fasta | wc -l)
            if [[ $nfiles -gt 1 ]]; then
                echo "Mitos could not be run, there are multiple files to run it on. Please check manually."
                touch {output}
                exit 0
            else
                runmitos.py -i output/{params.id}/annotation/alignment/clustalo/{params.id}.{params.sub}.{params.assembler}.rolled.*.fasta -o {params.outdir} -r dbs/mitos/mitos1-refdata -c {params.genetic_code}
                # copy rolled + RC assemblies to report directory
                cp output/{params.id}/annotation/alignment/clustalo/{params.id}.{params.sub}.{params.assembler}.rolled.*.fasta output/{params.id}/annotation/alignment/{params.id}.{params.sub}.{params.assembler}.final.fasta
                fi
        else
	        echo "Mitos could not be run because the input file is missing. Maybe the assembler did not produce output?" >> {log.stderr}
        fi
        if [[ -f {params.outdir}/result.bed ]]
	then
		awk '{{$1= "{params.id}.{params.sub}.{params.assembler}"; print $0}}' {params.outdir}/result.bed > {params.outdir}/tmp && mv {params.outdir}/tmp {params.outdir}/result.bed
		sed -i 's/ /\t/g' {params.outdir}/result.bed 
		sed -i 's#^>#>{params.id}.{params.sub}.{params.assembler}#g' output/{params.id}/annotation/alignment/{params.id}.{params.sub}.{params.assembler}.final.fasta
        fi
        touch {output}
        """

rule gene_positions:
    input:
        #rules.second_mitos.output
        #expand(rules.second_mitos.output, id=IDS, sub=sub, assembler=Assembler)
        expand("output/{id}/annotation/second_mitos/{id}.{sub}.{assembler}.second_mitos.done", zip, id=IDS, sub=sub, assembler=Assembler) 
        #"output/{id}/annotation/second_mitos/{id}.{sub}.{assembler}.second_mitos.done"
        #"compare/alignment/mitos2/mitos2_paths.txt"
    output:
        "output/{id}/annotation/compare/gene_positions.done"
        #positions = "compare/alignment/mitos2/Gene_positions.txt"
    shell:
        """
        find ./output/*/annotation/second_mitos/*/ -name "result.bed" | cat > output/stats/mitos2_paths.txt        
        scripts/gene_positions.py output/stats/mitos2_paths.txt output/stats/Gene_positions.txt
        touch {output}
        """
