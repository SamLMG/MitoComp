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
        outdir = "assemblies/novoplasty/{id}/{sub}/run"
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
	# if novoplasty was run before, remove the previous run
	if [ -d {params.outdir} ]; then rm -rf {params.outdir}; fi
        mkdir -p {params.outdir}
        cd {params.outdir}

	# run novoplasty - capture returncode, so if it fails, the pipeline won't stop
        NOVOPlasty.pl -c $WD/{input.config} 1> $WD/{log.stdout} 2> $WD/{log.stderr} && returncode=$? || returncode=$?
        if [ $returncode -gt 0 ]
        then
            echo -e "\\n#### [$(date)]\\tnovoplasty exited with an error - moving on - for details see: $WD/{log.stderr}" 1>> $WD/{log.stdout}
        fi

	# find the expected final assembly file
        final_fasta=$(find ./ -name "Circularized_assembly*")
	# check if the search returned only one file and copy if yes
        if [ "$(echo $final_fasta | tr ' ' '\\n' | wc -l)" -eq 1 ]
        then
            cp $WD/{params.outdir}/$final_fasta $WD/{params.outdir}/../{wildcards.id}.novoplasty.{wildcards.sub}.fasta 
	elif [ "$(echo $final_fasta | tr ' ' '\\n' | wc -l)" -eq 0 ]
        then
            echo -e "\\n#### [$(date)]\\tnovoplasty has not produced a circularized assembly - moving on" 1>> $WD/{log.stdout}
            touch $WD/{params.outdir}/../{wildcards.id}.novoplasty.{wildcards.sub}.fasta.missing
        elif [ "$(echo $final_fasta | tr ' ' '\\n' | wc -l)" -gt 1 ]
        then
            echo -e "\\n#### [$(date)]\\tnovoplasty seems to have produced multiple circularized assemblies - don't know which to pick - moving on" 1>> $WD/{log.stdout}
            touch $WD/{params.outdir}/../{wildcards.id}.novoplasty.{wildcards.sub}.fasta.missing
        fi

        touch $WD/{output.ok}
        """
