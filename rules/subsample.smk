rule subsample:
    input:
        f = rules.trimmomatic.output.fout,
        r = rules.trimmomatic.output.rout
    output:
        f = "sub/{sub}/{id}_1.fastq.gz",
        r = "sub/{sub}/{id}_2.fastq.gz"
    resources:
        qos="normal_binf -C binf",
        partition="binf",
        mem="100G",
        name="subsample",
        nnode="-N 1"
    params: 
        seed=553353,
    threads: 24
    conda:
        "envs/seqtk.yml"
    shell:
        """
        seqtk sample -s{params.seed} {input.f} {wildcards.sub} | gzip > {output.f}
        seqtk sample -s{params.seed} {input.r} {wildcards.sub} | gzip > {output.r}
        """
