rule roll:
    input:
#        mitos = expand("assemblies/{assembler}/{{id}}/{sub}/mitos.done", id=IDS, sub=sub, assembler=Assembler),
        #"compare/start_positions.txt",
        rules.annotation_stats.output,
        #fasta = expand("assemblies/{assembler}/{id}/{sub}/{id}.{assembler}.{sub}.fasta", id=IDS, sub=sub, assembler=Assembler)
    output:
#        "compare/{assembler}/{{id}}/{sub}/alignment/muscle/arrange.{assembler}.{{id}}.{sub}.done"
#        "output/{id}/annotation/alignment/roll.done"
#        RC_assemblies = "compare/RC_assemblies.txt"
         "output/stats/roll.done"
    singularity:
        "docker://python:2.7.18-stretch"
#    params:
#        id = "{id}"
#        outdir = "compare/alignment"
#        fasta = "assemblies/{assembler}/{id}/{sub}/{id}.{assembler}.{sub}.fasta"
#        #start = "bin/start_positions.txt" 
    shell:
        """
        while read first rest 
            file=$first
            position=$rest
            prefix1=$(echo $first | cut -d "/" -f3 | cut -d "." -f 1)
            prefix2=$(echo $first | cut -d "/" -f3 | cut -d "." -f 1-3)
        do
            if [[ $first == "" ]]; then
                break
            fi
            if [[ ! -d output/$prefix1/annotation/alignment/ ]]; then
                mkdir output/$prefix1/annotation/alignment/
            fi
            scripts/circules.py -f $file -n $position -p output/$prefix1/annotation/alignment/$prefix2
        done < output/stats/start_positions.txt
        touch {output}
        """
#    run:
#        roll = "scripts/circules.py"
#        sampleid = wildcards.id 
#        with open(input[0]) as file:    
#            for line in file:
#                if sampleid not in line:
#                      continue
#                line = line.strip()
#                print(line)
#                print(roll + " -f " +line.split('\t')[0] + " -n " +line.split('\t')[1] + " -p " + "output/" + wildcards.id + "/annotation/alignment/" + line.split('\t')[0].split('/')[-1].strip(".fasta"))
#                shell(roll + " -f " +line.split('\t')[0] + " -n " +line.split('\t')[1] + " -p " + "output/" + wildcards.id + "/annotation/alignment/" + line.split('\t')[0].split('/')[-1].strip(".fasta"))
#        shell("touch {output}")
#       shell("touch "+ output[0])  #python version of above line

###some assemblies orientated in reverse complement so should be reversed
rule reverse_complement:
    input:
        rules.roll.output,
        RC_assemblies = "output/stats/RC_assemblies.txt"
    output:
        "output/{id}/annotation/alignment/RC.done"
#    singularity:
#        "docker://reslp/biopython_plus"
    params:
        id = "{id}"
    shell:
        """
        mkdir -p output/{params.id}/annotation/alignment/clustalo
        scripts/RComp.py {params.id}
        touch {output}
        """

#rule report_prep:
#    input:
#        rules.reverse_complement.output
#    output:
#        fastas = "output/compare/report/assemblies/{id}.{assembler}.{sub}.fasta"
#    params:
#        id = "{id}",
#        assembler = "{assembler}",
#        sub = "{sub}"
#    shell:
#        """
#        # copy rolled + RC assemblies to report directory
#        mkdir -p ../../report/assemblies
#        cp {params.id}*.fasta ../../report/assemblies/{params.id}.{params.assembler}.{params.sub}.fasta
#        """

rule align:
    input:
        rules.reverse_complement.output
    output:
        "output/{id}/annotation/alignment/clustalo/{id}.align.done"
        #done = "output/compare/alignment/clustalo/align.done"
    params:
        id = "{id}"
    singularity: "docker://reslp/clustalo:1.2.4" 
    threads: config["threads"]["alignment"]
    shell:
        """
	cd output/{params.id}/annotation/alignment
	# cp has to fail silently of no RC file is found
        if [[ $(find {params.id}.*.rolled*.fasta) ]]; then
            cp {params.id}.*.rolled*.fasta clustalo/ 2>/dev/null || :
            #cp *.fasta clustalo/ 2>/dev/null || :
            cd clustalo
            for file in $(find *_RC.fasta); do 
		rm -f $(echo $file | sed 's/_RC//')
	    done
            no_assemblies=$(find {params.id}.*.rolled*.fasta | wc -l)
	    if [[ "$no_assemblies" -gt 1 ]]; then 
	    	cat {params.id}*.fasta > all_{params.id}_assemblies.fasta
            	clustalo -i all_{params.id}_assemblies.fasta -o {params.id}_alignment.fa --threads={threads}
            	touch {params.id}.align.done
	    else
		echo "There is only a single assembly for this ID so cannot align"
		touch {params.id}.align.done
	    fi
        else
            echo "Align could not be run because the input file is missing. This may happen when the assembler did not produce output or when MITOS did not find the most found gene in this assembly. This may also occur if there is only a single assembly for this ID"
            cd ../../../../
            #touch {params.id}.align.done
            touch {output}
        fi
        #touch {output}
        """
