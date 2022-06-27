rule subsample:
    input:
        f = rules.trimmomatic.output.fout,
        r = rules.trimmomatic.output.rout
    output:
        f = "output/{id}/reads/sub/{sub}/{id}_1.fastq.gz",
        r = "output/{id}/reads/sub/{sub}/{id}_2.fastq.gz",
        ok = "output/{id}/reads/sub/{sub}/{id}_{sub}.ok"
#    resources:
#        qos="normal_binf -C binf",
#        partition="binf",
#        mem="100G",
#        name="subsample",
#        nnode="-N 1"
    params: 
        seed= config["subsample"]["seed"],
        wd = os.getcwd()
    threads: config["threads"]["subsample"] 
    singularity:
        "docker://reslp/seqtk:1.3"
    shell:
        """
        if [[ {wildcards.sub} == "all" ]]; then 
            ln -s {params.wd}/{input.f} {params.wd}/{output.f}
            ln -s {params.wd}/{input.r} {params.wd}/{output.r}          
        else 
            seqtk sample -s{params.seed} {input.f} {wildcards.sub} | gzip > {output.f}
            seqtk sample -s{params.seed} {input.r} {wildcards.sub} | gzip > {output.r}
        fi
        touch {output.ok}
        """
