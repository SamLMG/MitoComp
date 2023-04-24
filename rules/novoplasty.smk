rule NOVOconfig:
    input:
        "bin/NOVOconfig.txt"
    output:
        "output/{id}/assemblies/{sub}/novoplasty/NOVOconfig_{id}_{sub}.txt"
    params:
        project_name = "{id}_{sub}",
        WD = os.getcwd(),
        seed = get_seed,
        log = "output/{id}/assemblies/{sub}/novoplasty/NOVOconfig_{id}_{sub}_log.txt",
        f = rules.subsample.output.f,
        r = rules.subsample.output.r,
        kmer = get_kmer,
        Read_length = get_readlength
    shell:
        """
        cp {input} {output}
        sed -i 's?^Project name.*?Project name = {params.project_name}?g' {output}
        sed -i 's?^Seed Input.*?Seed Input = {params.WD}/{params.seed}?g' {output}
        sed -i 's?^Extended log.*?Extended log = {params.WD}/{params.log}?g' {output}
        sed -i 's?^Forward reads.*?Forward reads = {params.WD}/{params.f}?g' {output}
        sed -i 's?^Reverse reads.*?Reverse reads = {params.WD}/{params.r}?g' {output}
        sed -i 's?^K-mer.*?K-mer = {params.kmer}?g' {output}
        sed -i 's?^Read Length.*?Read Length = {params.Read_length}?g' {output}
        """

rule NOVOplasty:
    input:
        config = rules.NOVOconfig.output,
        ok = rules.subsample.output.ok
    output: 
        ok = "output/{id}/assemblies/{sub}/novoplasty/novoplasty.ok"
    params:
        outdir = "output/{id}/assemblies/{sub}/novoplasty/run"
    log:
        stdout = "output/{id}/assemblies/{sub}/novoplasty/stdout.txt",
        stderr = "output/{id}/assemblies/{sub}/novoplasty/stderr.txt"
    benchmark: "output/{id}/assemblies/{sub}/novoplasty/{id}.{sub}.novoplasty.benchmark.txt"
    threads: config["threads"]["novoplasty"] 
    singularity: "docker://reslp/novoplasty:4.2"
    shell:
        """
        if [[ ! -d output/gathered_assemblies/ ]]; then mkdir output/gathered_assemblies/; fi
        WD=$(pwd)
            # if novoplasty was run before, remove the previous run
            if [ -d {params.outdir} ]; then rm -rf {params.outdir}; fi
        mkdir -p {params.outdir}
        cd {params.outdir}

        NOVOPlasty.pl -c $WD/{input.config} 1> $WD/{log.stdout} 2> $WD/{log.stderr} && returncode=$? || returncode=$?
        if [ $returncode -gt 0 ]
        then
            echo -e "\\n#### [$(date)]\\tnovoplasty exited with an error - moving on - for details see: $WD/{log.stderr}" 1>> $WD/{log.stdout}
        fi

        # find the expected final assembly file
        final_fasta=$(find ./ -name "Circularized_assembly*")
        # check if the variable is empty
        if [[ -z $final_fasta ]]
        then
            echo -e "\\n#### [$(date)]\\tnovoplasty has not produced a circularized assembly - moving on" 1>> $WD/{log.stdout}
            touch $WD/{params.outdir}/../{wildcards.id}.{wildcards.sub}.novoplasty.fasta.missing
        elif [ "$(echo $final_fasta | tr ' ' '\\n' | wc -l)" -eq 1 ] && [ $(grep "^>" $final_fasta | wc -l) -eq 1 ]
        then
            cp $WD/{params.outdir}/$final_fasta $WD/{params.outdir}/../{wildcards.id}.{wildcards.sub}.novoplasty.fasta
            cp $WD/{params.outdir}/$final_fasta $WD/output/gathered_assemblies/{wildcards.id}.{wildcards.sub}.novoplasty.fasta
        else
            echo -e "\\n#### [$(date)]\\tnovoplasty seems to have produced multiple circularized assemblies or assemblies containing multiple sequences - don't know which to pick - moving on" 1>> {log.stdout}
            touch {params.outdir}/../{wildcards.id}.{wildcards.sub}.novoplasty.fasta.missing
        fi
        touch $WD/{output.ok}
        """
