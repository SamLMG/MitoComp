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
        outdir = "assemblies/getorganelle/{id}/{sub}",
        seed = get_seed
    singularity:"docker://reslp/getorganelle:1.7.1"
#    conda:
#        "envs/getorganelle.yml"
    log:
        "assemblies/getorganelle/{id}/{sub}/getorganelle_log_{id}_{sub}.log"
    threads: 24
    shell:
        """
        get_organelle_from_reads.py -1 {input.f} -2 {input.r} -o {params.outdir} -F animal_mt -t {threads} -R 10 -s {params.seed}
        #get the path to the one fasta file in the output directory (assumes there is only one)
        final_fasta=$(ls $(pwd)/{params.outdir}/*.fasta)
        #create a symbolic link between the final fasta file and the output file as specified in the rule above
        touch {output.ok}
        """
#        ln -s $final_fasta $(pwd)/{output.fasta}
