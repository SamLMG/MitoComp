rule interleave:
    input:
        rules.subsample.output
#        r = rules.subsample.output.r,
#    resources:
#        qos="normal_0064",
#        partition="mem_0064",
#        mem="10G",
#        name="interleave",
#        nnode="-N 1"
    threads: config["threads"]["interleave"]
    output:
        "reads/interleave/{sub}/{id}_interleaved.fastq"
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
#        fasta = "assemblies/mitobim/{id}/{sub}/{id}.mitobim.{sub}.fasta",
        ok = "output/assemblies/mitobim/{id}/{sub}/mitobim.ok"
#    resources:
#        qos="normal_0128",
#        partition="mem_0128",
#        mem="60G",
#        name="MITObim",
#        nnode="-N 1"
    params:
        id = "{id}",
        seed = get_seed,
        wd = os.getcwd(),
        outdir = "output/assemblies/mitobim/{id}/{sub}/run"
    log: 
        stdout = "output/assemblies/mitobim/{id}/{sub}/stdout.txt",
        stderr = "output/assemblies/mitobim/{id}/{sub}/stderr.txt"
    benchmark: "output/assemblies/mitobim/{id}/{sub}/mitobim.{id}.{sub}.benchmark.txt"
    singularity:
        "docker://chrishah/mitobim:v.1.9.1"
#    shadow: "shallow"
    threads: config["threads"]["mitobim"] 
    shell:
        """
        WD=$(pwd)
        if [ -d {params.outdir} ]; then rm -rf {params.outdir}; fi
        mkdir -p {params.outdir}
        cd {params.outdir}
	
        # run mitobim - capture returncode, so if it fails, the pipeline won't stop
        MITObim.pl -sample {params.id} -ref {params.id} -readpool $WD/{input} --quick $WD/{params.seed} -end 100 --paired --clean --NFS_warn_only 1> $WD/{log.stdout} 2> $WD/{log.stderr} && returncode=$? || returncode=$?
        if [ $returncode -gt 0 ]
        then
            echo -e "\\n#### [$(date)]\\tmitobim exited with an error - moving on - for details see: $WD/{log.stderr}" 1>> $WD/{log.stdout}
        fi

        #if the expected final assembly exists, get a copy
        final_fasta=$(find ./ -name "*noIUPAC.fasta")
	# check if the search returned only one file and copy if yes
        if [ "$(echo $final_fasta | tr ' ' '\\n' | wc -l)" -eq 1 ]
        then
            cp $WD/{params.outdir}/$final_fasta $WD/{params.outdir}/../{wildcards.id}.mitobim.{wildcards.sub}.fasta
	elif [ "$(echo $final_fasta | tr ' ' '\\n' | wc -l)" -eq 0 ]
        then
            echo -e "\\n#### [$(date)]\\tmitobim has not produced a final assembly - moving on" 1>> $WD/{log.stdout}
            touch $WD/{params.outdir}/../{wildcards.id}.mitobim.{wildcards.sub}.fasta.missing
        fi

        touch $WD/{output.ok}       
        """

