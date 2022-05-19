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
                # copy new bed files to report directory with informative name
                #mkdir -p output/compare/report/bedfiles
                #cp output/compare/alignment/mitos2/{params.id}.{params.sub}.{params.assembler}/result.bed output/compare/report/bedfiles/{params.id}.{params.sub}.{params.assembler}.bed 
                # copy rolled + RC assemblies to report directory
                #mkdir -p output/compare/report/assemblies
                #cp output/compare/alignment/clustalo/{params.id}.{params.assembler}.{params.sub}*.fasta output/compare/report/assemblies/{params.id}.{params.assembler}.{params.sub}.fasta
                cp output/{params.id}/annotation/alignment/clustalo/{params.id}.{params.sub}.{params.assembler}.rolled.*.fasta output/{params.id}/annotation/alignment/{params.id}.{params.sub}.{params.assembler}.final.fasta
                fi
        else
        echo "Mitos could not be run because the input file is missing. Maybe the assembler did not produce output?" >> {log.stderr}
        fi
        if [[ $(find output/{params.id}/annotation/mitos/{params.id}.{params.sub}.{params.assembler}/result.bed) != "" ]]; then cp output/{params.id}/annotation/mitos/{params.id}.{params.sub}.{params.assembler}/result.bed {params.outdir}/result.bed
        awk '{{$1= "{params.id}.{params.sub}.{params.assembler}"; print $0}}' output/{params.id}/annotation/second_mitos/{params.id}.{params.sub}.{params.assembler}/result.bed > output/{params.id}/annotation/second_mitos/{params.id}.{params.sub}.{params.assembler}/tmp && mv output/{params.id}/annotation/second_mitos/{params.id}.{params.sub}.{params.assembler}/tmp output/{params.id}/annotation/second_mitos/{params.id}.{params.sub}.{params.assembler}/result.bed
        sed -i 's/ /\t/g' output/{params.id}/annotation/second_mitos/{params.id}.{params.sub}.{params.assembler}/result.bed 
        cp output/{params.id}/assemblies/{params.sub}/{params.assembler}/{params.id}.{params.sub}.{params.assembler}.fasta output/{params.id}/annotation/alignment/{params.id}.{params.sub}.{params.assembler}.final.fasta
        sed -i 's#^>#>{params.id}.{params.sub}.{params.assembler}#g' output/{params.id}/annotation/alignment/{params.id}.{params.sub}.{params.assembler}.final.fasta
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
        "output/{id}/annotation/compare/gene_positions.done"
        #positions = "compare/alignment/mitos2/Gene_positions.txt"
    shell:
        """
        find ./output/*/annotation/second_mitos/*/ -name "result.bed" | cat > output/stats/mitos2_paths.txt        
        scripts/gene_positions.py output/stats/mitos2_paths.txt output/stats/Gene_positions.txt
        touch {output}
        """
