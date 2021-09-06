rule roll:
    input:
#        mitos = expand("assemblies/{assembler}/{{id}}/{sub}/mitos.done", id=IDS, sub=sub, assembler=Assembler),
        #"compare/start_positions.txt",
        rules.annotation_stats.output,
        #fasta = expand("assemblies/{assembler}/{id}/{sub}/{id}.{assembler}.{sub}.fasta", id=IDS, sub=sub, assembler=Assembler)
    output:
#        "compare/{assembler}/{{id}}/{sub}/alignment/muscle/arrange.{assembler}.{{id}}.{sub}.done"
        done = "output/compare/alignment/roll.done",
#        RC_assemblies = "compare/RC_assemblies.txt"
#    params:
#        outdir = "compare/alignment"
#        fasta = "assemblies/{assembler}/{id}/{sub}/{id}.{assembler}.{sub}.fasta"
#        #start = "bin/start_positions.txt" 
    run:
        roll = "scripts/circules.py"
        with open(input[0]) as file:    
            for line in file:
#            roll = scripts/circules.py -f +line.split('\t')[0] -n +line.split('\t')[1]
                line = line.strip()
                print(roll + " -f " +line.split('\t')[0] + " -n " +line.split('\t')[1] + " -p " + "output/compare/alignment/" + line.split('\t')[0].split('/')[-1].strip(".fasta")) 
                shell(roll + " -f " +line.split('\t')[0] + " -n " +line.split('\t')[1] + " -p " + "output/compare/alignment/" + line.split('\t')[0].split('/')[-1].strip(".fasta"))
        shell("touch {output}")
#       shell("touch "+ output[0])  #python version of above line

###some assemblies orientated in reverse complement so should be reversed
rule reverse_complement:
    input:
        rules.roll.output,
        RC_assemblies = "output/compare/RC_assemblies.txt"
    output:
        "output/compare/alignment/RC.done"
#    singularity:
#        "docker://reslp/biopython_plus"
    shell:
        """
        mkdir -p output/compare/alignment/clustalo
        scripts/RComp.py
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
        id_done = "output/compare/alignment/clustalo/{id}.align.done",
        #done = "output/compare/alignment/clustalo/align.done"
    params:
        id = "{id}"
    singularity: "docker://reslp/clustalo:1.2.4" 
    threads: config["threads"]["alignment"]
    shell:
        """
	cd output/compare/alignment
	# cp has to fail silently of no RC file is found
        if [[ -f output/compare/alignment/{params.id}.rolled*.fasta ]]; then
            cp {params.id}*.fasta clustalo/ 2>/dev/null || :
            #cp *.fasta clustalo/ 2>/dev/null || :
            cd clustalo
            cat {params.id}*.fasta > all_{params.id}_assemblies.fasta
            clustalo -i all_{params.id}_assemblies.fasta -o {params.id}_alignment.fa --threads={threads}
            touch {params.id}.align.done
        else
            echo "Align could not be run because the input file is missing. This may happen when the assembler did not produce output or when MITOS did not find the most found gene in this assembly?"
            cd ../../../
            #touch {params.id}.align.done
            touch {output}
        fi
        #touch {output}
        """
