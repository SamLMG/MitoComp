rule trimmomatic:
    input:
        f = rules.fastqdump.output.f,
        r = rules.fastqdump.output.r
    resources:
        qos="normal_binf -C binf",
        partition="binf",
        mem="100G",
        name="trimmomatic",
        nnode="-N 1"
    output:
        fout = "trimmed/{id}_1P_trim.fastq.gz",
        funp = "trimmed/{id}_1P_unpaired.fastq.gz",
        rout = "trimmed/{id}_2P_trim.fastq.gz",
        runp = "trimmed/{id}_2P_unpaired.fastq.gz",
        ok = "trimmed/trim_{id}.ok"
    threads: config["threads"]["trimming"] 
    singularity: 
        "docker://reslp/trimmomatic:0.38"
    shell:
        """
        trimmomatic PE -threads {threads} {input.f} {input.r} {output.fout} {output.funp} {output.rout} {output.runp} ILLUMINACLIP:adapterseq/Adapters_PE.fa:2:30:10: LEADING:30 TRAILING:30 SLIDINGWINDOW:4:15 MINLEN:80
        touch {output.ok}
        """
