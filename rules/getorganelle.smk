rule get_organelle:
    input:
        ok = rules.subsample.output,
        f = rules.subsample.output.f,
        r = rules.subsample.output.r
    output:
        ok = "output/{id}/assemblies/{sub}/getorganelle/getorganelle.ok"
    params:
        outdir = "output/{id}/assemblies/{sub}/getorganelle/run",
        seed = get_seed,
        type = get_type,
        rounds = get_rounds
    singularity:"docker://reslp/getorganelle:1.7.1"
    log:
        stdout = "output/{id}/assemblies/{sub}/getorganelle/stdout.txt",
        stderr = "output/{id}/assemblies/{sub}/getorganelle/stderr.txt" 
    benchmark: "output/{id}/assemblies/{sub}/getorganelle/{id}.{sub}.getorganelle.benchmark.txt"
    threads: config["threads"]["getorganelle"] 
    shell:
        """
        # run getorganelle - capture returncode, so if it fails, the pipeline won't stop
        if [[ ! -d output/gathered_assemblies/ ]]; then mkdir output/gathered_assemblies/; fi
        get_organelle_from_reads.py -1 {input.f} -2 {input.r} -o {params.outdir} -F {params.type} -t {threads} -R {params.rounds} -s {params.seed} 1> {log.stdout} 2> {log.stderr} && returncode=$? || returncode=$?
        if [ $returncode -gt 0 ]
        then
            echo -e "\\n#### [$(date)]\\tgetorganelle exited with an error - moving on - for details see: $(pwd)/{log.stderr}" 1>> {log.stdout}
            touch {params.outdir}/../{wildcards.id}.{wildcards.sub}.getorganelle.fasta.missing
        fi

        #if the expected final assembly exists, get a copy
        if [[ -d $(pwd)/{params.outdir} ]]
        then #check first of folder exists in case get_organelle exits with the wrong exit code.
            final_fasta=$(find $(pwd)/{params.outdir}/ -maxdepth 1 -name "*.fasta")
        fi
        # check if the search returned only one file and copy if yes -- also check only 1 sequence in final fasta
        if [[ -z $final_fasta ]] 
        then
            echo -e "\\n#### [$(date)]\\tgetorganelle has not produced the final assembly - moving on" 1>> {log.stdout}
            touch {params.outdir}/../{wildcards.id}.{wildcards.sub}.getorganelle.fasta.missing
        elif [ "$(echo $final_fasta | tr ' ' '\\n' | wc -l)" -eq 1 ] && [ $(grep "^>" $final_fasta | wc -l) -eq 1 ]
        then
            cp $final_fasta {params.outdir}/../{wildcards.id}.{wildcards.sub}.getorganelle.fasta
            cp $final_fasta output/gathered_assemblies/{wildcards.id}.{wildcards.sub}.getorganelle.fasta
        else
            echo -e "\\n#### [$(date)]\\tgetorganelle seems to have produced multiple assemblies or assemblies containing multiple sequences - don't know which to pick - moving on" 1>> {log.stdout}
            touch {params.outdir}/../{wildcards.id}.{wildcards.sub}.getorganelle.fasta.missing
        fi
        touch {output.ok}
        """
