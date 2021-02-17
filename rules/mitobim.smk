rule interleave:
    input:
        f = rules.subsample.output.f,
        r = rules.subsample.output.r,
#    resources:
#        qos="normal_0064",
#        partition="mem_0064",
#        mem="10G",
#        name="interleave",
#        nnode="-N 1"
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
#        fasta = "assemblies/{assembler}/{id}/{sub}/{id}_{assembler}_coxI.fasta",
        ok = "assemblies/mitobim/{id}/{sub}/mitobim.ok"
#    resources:
#        qos="normal_binf -C binf",
#        partition="binf",
#        mem="100G",
#        name="MITObim",
#        nnode="-N 1"
    params:
        id = "{id}",
        seed = get_seed,
        wd = os.getcwd()
    log: "assemblies/mitobim/{id}/{sub}/{id}_mitobim_{sub}.log"
    singularity:
        "docker://chrishah/mitobim:v.1.9.1"
    shadow: "shallow"
    threads: 10
    shell:
        """
        MITObim.pl -sample {params.id} -ref {params.id}_coxI -readpool {input} --quick {params.seed} -end 100 --paired --clean --NFS_warn_only &> {log}
        touch {output.ok}       
        """ 
#        cp $(find ./ -name "*noIUPAC.fasta") {output.fasta}
