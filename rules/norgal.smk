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
        # add a directory from the container to the PATH, so norgal finds all necessary executables
        export PATH="/software/norgal/binaries/linux:$PATH"
	# if norgal was run before, remove the previous run
	if [ -d {params.outdir} ]; then rm -rf {params.outdir}; fi

        # run norgal - capture returncode, so if it fails, the pipeline won't stop
        norgal.py -i {input.f} {input.r} -o {params.outdir} --blast -t {threads} 1> $WD/{log.stdout} 2> $WD/{log.stderr} && returncode=$? || returncode=$? 
        if [ $returncode -gt 0 ]
        then
            echo -e "\\n#### [$(date)]\\tnorgal exited with an error - see above - moving on" 2>> $WD/{log.stderr}
        fi

	#if the expected final assembly exists, get a copy
        if [ -f $WD/assemblies/norgal/{wildcards.id}/{wildcards.sub}/run/circular.candidate.fa ]
        then
            cp $WD/assemblies/norgal/{wildcards.id}/{wildcards.sub}/run/circular.candidate.fa $WD/assemblies/norgal/{wildcards.id}/{wildcards.sub}/{wildcards.id}.norgal.{wildcards.sub}.fasta
        else
            echo -e "\\n#### [$(date)]\\tnorgal did not find a circular candidate assembly - moving on" 2>> $WD/{log.stderr} 
        fi

        touch {output.ok}
        """

