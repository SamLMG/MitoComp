##rule download_GO_database:
##    output:
##       "get_organelle.db.ok"
##    conda:
##       "envs/getorganelle.yml" 
##    threads: 1
##    shell:
##       """
##       get_organelle_config.py --clean
##       get_organelle_config.py -a animal_mt
##       touch {output}
##       """
#
#
rule get_organelle:
    input:
#        ok = rules.download_GO_database.output,
        f = rules.subsample.output.f,
        r = rules.subsample.output.r
    output:
#        fasta = "assemblies/{assembler}/{id}/{sub}/{id}.getorganelle.final.fasta",
        ok = "assemblies/getorganelle/{id}/{sub}/getorganelle.ok"
#    resources:
#        qos="normal_binf -C binf",
#        partition="binf",
#        mem="100G",
#        name="getorganelle",
#        nnode="-N 1"
    params:
        outdir = "assemblies/getorganelle/{id}/{sub}/run",
        seed = get_seed,
        type = get_type,
        rounds = get_rounds
    singularity:"docker://reslp/getorganelle:1.7.1"
#    conda:
#        "envs/getorganelle.yml"
    log:
        stdout = "assemblies/getorganelle/{id}/{sub}/stdout.txt",
        stderr = "assemblies/getorganelle/{id}/{sub}/stderr.txt" 
    benchmark: "assemblies/getorganelle/{id}/{sub}/getorganelle.{id}.{sub}.benchmark.txt"
    threads: config["threads"]["getorganelle"] 
    shell:
        """
        # run getorganelle - capture returncode, so if it fails, the pipeline won't stop
        get_organelle_from_reads.py -1 {input.f} -2 {input.r} -o {params.outdir} -F {params.type} -t {threads} -R {params.rounds} -s {params.seed} 1> {log.stdout} 2> {log.stderr} && returncode=$? || returncode=$?
        if [ $returncode -gt 0 ]
        then
            echo -e "\\n#### [$(date)]\\tgetorganelle exited with an error - moving on - for details see: $(pwd)/{log.stderr}" 1>> {log.stdout}
        fi

        #if the expected final assembly exists, get a copy
        if [[ -d  $(pwd)/{params.outdir} ]]; then #check first of folder exists in case get_organelle exits with the wrong exit code.
		final_fasta=$(ls $(pwd)/{params.outdir}/*.fasta)
	else
		final_fasta=""
	fi
	# check if the search returned only one file and copy if yes
        if [ "$(echo $final_fasta | tr ' ' '\\n' | wc -l)" -eq 1 ]
        then
            cp $final_fasta $(pwd)/{params.outdir}/../{wildcards.id}.getorganelle.{wildcards.sub}.fasta
	elif [ "$(echo $final_fasta | tr ' ' '\\n' | wc -l)" -eq 0 ]
        then
            echo -e "\\n#### [$(date)]\\tgetorganelle has not produced the final assembly - moving on" 1>> {log.stdout}
            touch $(pwd)/{params.outdir}/../{wildcards.id}.getorganelle.{wildcards.sub}.fasta.missing
        fi

        touch {output.ok}
        """
