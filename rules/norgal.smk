rule norgal:
    input:
        ok = rules.subsample.output.ok,
        f = rules.subsample.output.f,
        r = rules.subsample.output.r
    output:
#        outdir = directory("assemblies/{assembler}/{id}/{sub}/{id}_{assembler}"),
        ok = "output/{id}/assemblies/{sub}/norgal/norgal.ok"
#    resources:
#        qos="normal_binf -C binf",
#        partition="binf",
#        mem="100G",
#        name="norgal",
#        nnode="-N 1"
    params:
        outdir = "output/{id}/assemblies/{sub}/norgal/run"
    log:
        stdout = "output/{id}/assemblies/{sub}/norgal/stdout.txt",
        stderr = "output/{id}/assemblies/{sub}/norgal/stderr.txt"
    benchmark: "output/{id}/assemblies/{sub}/norgal/{id}.{sub}.norgal.benchmark.txt"
    threads: config["threads"]["norgal"] 
    singularity: "docker://reslp/norgal:1.0"
    shell:
        """
        if [[ ! -d output/gathered_assemblies/ ]]; then mkdir output/gathered_assemblies/; fi
        WD=$(pwd)
        # add a directory from the container to the PATH, so norgal finds all necessary executables
        export PATH="/software/norgal/binaries/linux:$PATH"
	# if norgal was run before, remove the previous run
	if [ -d {params.outdir} ]; then rm -rf {params.outdir}; fi

        # run norgal - capture returncode, so if it fails, the pipeline won't stop
        norgal.py -i {input.f} {input.r} -o {params.outdir} --blast -t {threads} 1> $WD/{log.stdout} 2> $WD/{log.stderr} && returncode=$? || returncode=$? 
        if [ $returncode -gt 0 ]
        then
            echo -e "\\n#### [$(date)]\\tnorgal exited with an error - moving on - for details see: $WD/{log.stderr}" 1>> $WD/{log.stdout}
        fi

	#if the expected final assembly exists, get a copy
        if [ -f $WD/output/{wildcards.id}/assemblies/{wildcards.sub}/norgal/run/circular.candidate.fa ]
        then
            cp $WD/output/{wildcards.id}/assemblies/{wildcards.sub}/norgal/run/circular.candidate.fa $WD/{params.outdir}/../{wildcards.id}.{wildcards.sub}.norgal.fasta
            cp $WD/{params.outdir}/../{wildcards.id}.{wildcards.sub}.norgal.fasta $WD/output/gathered_assemblies/{wildcards.id}.{wildcards.sub}.norgal.fasta
	else
            echo -e "\\n#### [$(date)]\\tnorgal did not find a circular candidate assembly - moving on" 1>> $WD/{log.stdout} 
            touch $WD/{params.outdir}/../{wildcards.id}.{wildcards.sub}.norgal.fasta.missing 
        fi

	touch {output.ok}
        """

