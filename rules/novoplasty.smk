rule NOVOconfig:
    input:
        "bin/NOVOconfig.txt"
    output:
        "assemblies/novoplasty/{id}/{sub}/NOVOconfig_{id}_{sub}.txt"
    params:
        project_name = "{id}",
        seed = get_seed,
        log = "assemblies/novoplasty/{id}/{sub}/NOVOconfig_{id}_{sub}_log.txt",
        f = rules.subsample.output.f,
        r = rules.subsample.output.r
    shell:
        """
        cp {input} {output}
        sed -i 's?^Project name.*?Project name = {params.project_name}?g' {output}
        sed -i 's?^Seed Input.*?Seed Input = {params.seed}?g' {output}
        sed -i 's?^Extended log.*?Extended log = {params.log}?g' {output}
        sed -i 's?^Forward reads.*?Forward reads = {params.f}?g' {output}
        sed -i 's?^Reverse reads.*?Reverse reads = {params.r}?g' {output}
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
#    resources:
#        qos="normal_binf -C binf",
#        partition="binf",
#        mem="100G",
#        name="NOVOplasty",
#        nnode="-N 1"
    log: "assemblies/novoplasty/{id}/{sub}/{id}_novoplasty_{sub}.log"
    threads: 24
    shadow: "shallow"
    conda:
       "envs/novoplasty.yml"
    shell:
       """
       scripts/NOVOPlasty4.2.1.pl -c {input.config}
       cp $(find ./ -name "*.fasta") {params.outdir}
       touch {output.ok}
       """
