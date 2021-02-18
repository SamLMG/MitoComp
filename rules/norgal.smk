rule norgal:
    input:
        f = rules.subsample.output.f,
        r = rules.subsample.output.r
    output:
#        outdir = directory("assemblies/{assembler}/{id}/{sub}/{id}_{assembler}"),
        ok = "assemblies/norgal/{id}/{sub}/norgal.ok"
    resources:
        qos="normal_binf -C binf",
        partition="binf",
        mem="100G",
        name="norgal",
        nnode="-N 1"
    params:
        outdir = "assemblies/norgal/{id}/{sub}/run"
    threads: 24
    singularity: "docker://reslp/norgal:1.0"
    shell:
        """
        export PATH="/software/norgal/binaries/linux:$PATH"
	if [ -d {params.outdir} ]; then rm -rf {params.outdir}; fi
        norgal.py -i {input.f} {input.r} -o {params.outdir} --blast -t {threads}
        touch {output.ok}
        """

