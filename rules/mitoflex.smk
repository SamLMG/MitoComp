rule setup_mitoflex_db:
    output: 
        ok = "bin/MitoFlex/mitoflex.db.status.ok",
    params:
        wd = os.getcwd(),
    singularity: "docker://samlmg/mitoflex:v0.2.9"
    threads: 1
    shell:
        """
        cp -pfr /MitoFlex/* bin/MitoFlex/
        cp bin/ncbi_custom.py bin/MitoFlex/ncbi.py
        cd bin/MitoFlex/
        export HOME=$(pwd)
        echo $HOME
	#execute modified ncbi.py script with 'y' or 'n' as additional options (our modification allows for non-interactive use of the script) - 'y' -> download taxdump; 'n' -> use existing taxdump
        ./ncbi.py y 
        touch {params.wd}/{output.ok}
        """

rule mitoflex:
    input:
        f = rules.subsample.output.f,
        r = rules.subsample.output.r,
        db = rules.setup_mitoflex_db.output
    output:
#        fasta = "assemblies/{assembler}/{id}/{sub}/{id}.picked.fa",
        ok = "assemblies/mitoflex/{id}/{sub}/mitoflex.ok",
#	run = directory("assemblies/{assembler}/{id}/{sub}/MitoFlex")
    params:
        wd = os.getcwd(),
	outdir = "assemblies/mitoflex/{id}/{sub}",
        id = "{id}",
        clade = get_clade,
        genetic_code = get_code 
    resources:
        qos="normal_binf -C binf",
        partition="binf",
        mem="100G",
        ntasks="24",
        name="MitoFlex",
        nnode="-N 1",
    log:
        stdout = "assemblies/mitoflex/{id}/{sub}/stdout.txt",
        stderr = "assemblies/mitoflex/{id}/{sub}/stderr.txt"
    threads: 24
    singularity: "docker://samlmg/mitoflex:v0.2.9"
#    shadow: "minimal"
    shell:
        """
        cd {params.outdir}
        export HOME="{params.wd}/bin/MitoFlex"

        # run mitoflex - capture returncode, so if it fails, the pipeline won't stop 
        {params.wd}/bin/MitoFlex/MitoFlex.py all --workname MitoFlex --threads {threads} --fastq1 {params.wd}/{input.f} --fastq2 {params.wd}/{input.r} --genetic-code {params.genetic_code} --clade {params.clade} 1> {params.wd}/{log.stdout} 2> {params.wd}/{log.stderr} && returncode=$? || returncode=$?
        if [ $returncode -gt 0 ]
        then
            echo -e "\\n#### [$(date)]\\tmitoflex exited with an error - see above - moving on" 2>> {params.wd}/{log.stderr}
        fi
 
	#if the expected final assembly exists, get a copy
        if [ -f MitoFlex/MitoFlex.result/MitoFlex.picked.fa ]
        then
            cp MitoFlex/MitoFlex.result/MitoFlex.picked.fa {params.wd}/{params.outdir}/{wildcards.id}.mitoflex.{wildcards.sub}.fasta
        else
            echo -e "\\n#### [$(date)]\\tmitoflex did not pick a final assembly - moving on" 2>> {params.wd}/{log.stderr} 
        fi

        touch {params.wd}/{output.ok}
        """
