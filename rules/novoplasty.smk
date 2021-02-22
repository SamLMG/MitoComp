rule NOVOconfig:
    input:
        "bin/NOVOconfig.txt"
    output:
        "assemblies/novoplasty/{id}/{sub}/NOVOconfig_{id}_{sub}.txt"
    params:
        project_name = "{id}_{sub}",
        WD = os.getcwd(),
        seed = get_seed,
        log = "assemblies/novoplasty/{id}/{sub}/NOVOconfig_{id}_{sub}_log.txt",
        f = rules.subsample.output.f,
        r = rules.subsample.output.r
    shell:
        """
        cp {input} {output}
        sed -i 's?^Project name.*?Project name = {params.WD}/{params.project_name}?g' {output}
        sed -i 's?^Seed Input.*?Seed Input = {params.WD}/{params.seed}?g' {output}
        sed -i 's?^Extended log.*?Extended log = {params.WD}/{params.log}?g' {output}
        sed -i 's?^Forward reads.*?Forward reads = {params.WD}/{params.f}?g' {output}
        sed -i 's?^Reverse reads.*?Reverse reads = {params.WD}/{params.r}?g' {output}
        """

rule NOVOplasty:
    input:
        config = rules.NOVOconfig.output,
        ok = rules.subsample.output.f
    output: 
#       fasta = "assemblies/{assembler}/{id}/{sub}/Circularized_assembly_1_{id}_{sub}_novoplasty.fasta",
        ok = "assemblies/novoplasty/{id}/{sub}/novoplasty.ok"
    params:
        outdir = "assemblies/novoplasty/{id}/{sub}"
    resources:
        qos="normal_binf -C binf",
        partition="binf",
        mem="100G",
        name="NOVOplasty",
        nnode="-N 1"
    log:
        stdout = "assemblies/novoplasty/{id}/{sub}/stdout.txt",
        stderr = "assemblies/novoplasty/{id}/{sub}/stderr.txt"
    threads: 24
#    shadow: "shallow"
#    conda:
#       "envs/novoplasty.yml"
    singularity: "docker://reslp/novoplasty:4.2"
    shell:
        """
        WD=$(pwd)
        mkdir -p {params.outdir}
        cd {params.outdir}
        NOVOPlasty4.2.pl -c {input.config} 1> {log.stdout} 2> {log.stderr}
        touch {output.ok}
        cp $(find ./ -name "Circularized_assembly*") {params.outdir}/{wildcards.id}.novoplasty.{wildcards.sub}.fasta
        """
