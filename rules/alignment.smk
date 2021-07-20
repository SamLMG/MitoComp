rule roll:
    input:
#        mitos = expand("assemblies/{assembler}/{{id}}/{sub}/mitos.done", id=IDS, sub=sub, assembler=Assembler),
        #"compare/start_positions.txt",
        rules.annotation_stats.output
        #fasta = "assemblies/{assembler}/{id}/{sub}/{id}.{assembler}.{sub}.fasta"
    output:
#        "compare/{assembler}/{{id}}/{sub}/alignment/muscle/arrange.{assembler}.{{id}}.{sub}.done"
        done = "compare/alignment/roll.done",
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
                print(roll + " -f " +line.split('\t')[0] + " -n " +line.split('\t')[1] + " -p " + "compare/alignment/" + line.split('\t')[0].split('/')[-1].strip(".fasta")) 
                shell(roll + " -f " +line.split('\t')[0] + " -n " +line.split('\t')[1] + " -p " + "compare/alignment/" + line.split('\t')[0].split('/')[-1].strip(".fasta"))
        shell("touch {output}")
#       shell("touch "+ output[0])  #python version of above line

###some assemblies orientated in reverse complement so should be reversed
rule reverse_complement:
    input:
        rules.roll.output,
        RC_assemblies = "compare/RC_assemblies.txt"
    output:
        "compare/alignment/RC.done"
#    singularity:
#        "docker://reslp/biopython_plus"
    shell:
        """
        mkdir -p compare/alignment/clustalo
        scripts/RComp.py
        touch {output}
        """

rule align:
    input:
        rules.reverse_complement.output
    output:
        done = "compare/alignment/clustalo/{id}.align.done"
#        "compare/{assembler}/{id}/{sub}/alignment/muscle/muscle.{assembler}.{id}.{sub}.done"
    params:
        id = "{id}"
#        outdir = "compare/alignment"    
    singularity: "docker://reslp/clustalo:1.2.4" 
    threads: config["threads"]["alignment"]
    shell:
        """
	cd compare/alignment
	# cp has to fail silently of no RC file is found
        cp *RC.fasta clustalo/ 2>/dev/null || :
        cd clustalo
        cat {params.id}*.fasta > all_{params.id}_assemblies.fasta
        clustalo -i all_{params.id}_assemblies.fasta -o {params.id}_alignment.fa --threads={threads}
        touch {params.id}.align.done
        """
