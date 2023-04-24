rule interleave:
    input:
        ok = rules.subsample.output.ok,
        f = rules.subsample.output.f,
        r = rules.subsample.output.r
    threads: config["threads"]["interleave"]
    output:
        "output/{id}/reads/interleave/{sub}/{id}_{sub}_interleaved.fastq"
    singularity:
        "docker://reslp/bbmap:38.90"
    shell:
        """
        reformat.sh in1={input.f} in2={input.r} out={output}
        """

rule MITObim:
    input:
        rules.interleave.output
    output:
        ok = "output/{id}/assemblies/{sub}/mitobim/mitobim.ok"
    params:
        id = "{id}",
        seed = get_seed,
        wd = os.getcwd(),
        outdir = "output/{id}/assemblies/{sub}/mitobim/run"
    log: 
        stdout = "output/{id}/assemblies/{sub}/mitobim/stdout.txt",
        stderr = "output/{id}/assemblies/{sub}/mitobim/stderr.txt"
    benchmark: "output/{id}/assemblies/{sub}/mitobim/{id}.{sub}.mitobim.benchmark.txt"
    singularity:
        "docker://chrishah/mitobim:v.1.9.1"
    threads: config["threads"]["mitobim"] 
    shell:
        """
        if [[ ! -d output/gathered_assemblies/ ]]; then mkdir output/gathered_assemblies/; fi
        WD=$(pwd)
        if [ -d {params.outdir} ]; then rm -rf {params.outdir}; fi
        mkdir -p {params.outdir}
        cd {params.outdir}
        
        # run mitobim - capture returncode, so if it fails, the pipeline won't stop
        MITObim.pl -sample {params.id} -ref seed -readpool $WD/{input} --quick $WD/{params.seed} -end 100 --paired --clean --NFS_warn_only 1> $WD/{log.stdout} 2> $WD/{log.stderr} && returncode=$? || returncode=$?
        if [ $returncode -gt 0 ]
        then
            echo -e "\\n#### [$(date)]\\tmitobim exited with an error - moving on - for details see: $WD/{log.stderr}" 1>> $WD/{log.stdout}
        fi

        #if the expected final assembly exists, get a copy
        final_fasta=$(find ./ -name "*noIUPAC.fasta")
        # check if the search returned only one file and copy if yes
        if [[ -z $final_fasta ]]
        then
            echo -e "\\n#### [$(date)]\\tmitobim has not produced a final assembly - moving on" 1>> $WD/{log.stdout}
            touch $WD/{params.outdir}/../{wildcards.id}.{wildcards.sub}.mitobim.fasta.missing
        elif [ "$(echo $final_fasta | tr ' ' '\\n' | wc -l)" -eq 1 ] && [ $(grep "^>" $final_fasta | wc -l) -eq 1 ]
        then
            cp $WD/{params.outdir}/$final_fasta $WD/{params.outdir}/../{wildcards.id}.{wildcards.sub}.mitobim.fasta
            cp $WD/{params.outdir}/$final_fasta $WD/output/gathered_assemblies/{wildcards.id}.{wildcards.sub}.mitobim.fasta
        else
            echo -e "\\n#### [$(date)]\\tmitobim seems to have produced multiple assemblies or assemblies containing multiple sequences - don't know which to pick - moving on" 1>> {log.stdout}
            touch {params.outdir}/../{wildcards.id}.{wildcards.sub}.mitobim.fasta.missing
        fi
        touch $WD/{output.ok}       
        """

