rule norgal:
    input:
        f = rules.subsample.output.f,
        r = rules.subsample.output.r
    output:
#        directory("assemblies/{assembler}/{id}/{sub}/{id}_{assembler}"),
        ok = "assemblies/norgal/{id}/{sub}/norgal.ok"
    resources:
        qos="normal_binf -C binf",
        partition="binf",
        mem="100G",
        name="norgal",
        nnode="-N 1"
    threads: 24
    singularity: "docker://reslp/norgal:1.0"
    shell:
        """
        export PATH="/software/norgal/binaries/linux:$PATH"        
        norgal.py -i {input.f} {input.r} -o {output} --blast -t {threads}
        touch {output}
        """
