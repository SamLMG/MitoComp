rule norgal:
    input:
        ok = rules.subsample.output.ok,
        f = rules.subsample.output.f,
        r = rules.subsample.output.r
    output:
        ok = "output/{id}/assemblies/{sub}/norgal/norgal.ok"
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
        final_fasta=$(find $(pwd)/{params.outdir}/ -name "circular.candidate.fa")
        # check if the search returned only one file and copy if yes
        if [[ -z $final_fasta ]]
        then
            echo -e "\\n#### [$(date)]\\tnorgal has not produced a circularized assembly - moving on" 1>> $WD/{log.stdout}
            touch $WD/{params.outdir}/../{wildcards.id}.{wildcards.sub}.norgal.fasta.missing
        elif [ "$(echo $final_fasta | tr ' ' '\\n' | wc -l)" -eq 1 ] && [ $(grep "^>" $final_fasta | wc -l) -eq 1 ]
        then
            cp $final_fasta {params.outdir}/../{wildcards.id}.{wildcards.sub}.norgal.fasta
            cp $final_fasta output/gathered_assemblies/{wildcards.id}.{wildcards.sub}.norgal.fasta
        else
            echo -e "\\n#### [$(date)]\\tnorgal seems to have produced multiple circularized assemblies or assemblies containing multiple sequences - don't know which to pick - moving on" 1>> {log.stdout}
            touch {params.outdir}/../{wildcards.id}.{wildcards.sub}.norgal.fasta.missing
        fi
        touch $WD/{output.ok}
        """

