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
    log:
        stdout = "assemblies/norgal/{id}/{sub}/stdout.txt",
        stderr = "assemblies/norgal/{id}/{sub}/stderr.txt"
    threads: 24
    singularity: "docker://reslp/norgal:1.0"
    shell:
        """
        WD=$(pwd)
        export PATH="/software/norgal/binaries/linux:$PATH"
	if [ -d {params.outdir} ]; then rm -rf {params.outdir}; fi
        norgal.py -i {input.f} {input.r} -o {params.outdir} --blast -t {threads} 1> $WD/{log.stdout} 2> $WD/{log.stderr}
        touch {output.ok}
        cp $(find ./ -name "*circular.candidate.fa") $WD/assemblies/norgal/{wildcards.id}/{wildcards.sub}/{wildcards.id}.norgal.{wildcards.sub}.fasta
        """

