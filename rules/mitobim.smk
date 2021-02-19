rule interleave:
    input:
        f = rules.subsample.output.f,
        r = rules.subsample.output.r,
    resources:
        qos="normal_0064",
        partition="mem_0064",
        mem="10G",
        name="interleave",
        nnode="-N 1"
    threads: 2
    output:
        "interleave/{sub}/{id}_interleaved.fastq"
    conda:
        "envs/bbmap.yml"
    shell:
        """
	reformat.sh in1={input.f} in2={input.r} out={output}
	"""

rule MITObim:
    input:
        rules.interleave.output
    output:
#        fasta = "assemblies/mitobim/{id}/{sub}/{id}.mitobim.{sub}.fasta",
        ok = "assemblies/mitobim/{id}/{sub}/mitobim.ok",
        rundir = "assemblies/mitobim/{id}/{sub}/run"
    resources:
        qos="normal_binf -C binf",
        partition="binf",
        mem="100G",
        name="MITObim",
        nnode="-N 1"
    params:
        id = "{id}",
        seed = get_seed,
        wd = os.getcwd()
    log: 
        stdout = "assemblies/mitobim/{id}/{sub}/stdout.txt",
        stderr = "assemblies/mitobim/{id}/{sub}/stderr.txt"
    singularity:
        "docker://chrishah/mitobim:v.1.9.1"
#    shadow: "shallow"
    threads: 10
    shell:
        """
        WD=$(pwd)
        mkdir -p {output.rundir}
        cd {output.rundir}
        MITObim.pl -sample {params.id} -ref {params.id} -readpool $WD/{input} --quick $WD/{params.seed} -end 100 --paired --clean --NFS_warn_only 1> $WD/{log.stdout} 2> $WD/{log.stderr}
        touch $WD/{output.ok}       
        cp $(find ./ -name "*noIUPAC.fasta") $WD/assemblies/mitobim/{wildcards.id}/{wildcards.sub}/{wildcards.id}.mitobim.{wildcards.sub}.fasta
        """ 
