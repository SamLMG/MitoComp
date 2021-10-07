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
        ok = rules.subsample.output.ok,
        f = rules.subsample.output.f,
        r = rules.subsample.output.r,
        db = rules.setup_mitoflex_db.output
    output:
#        fasta = "assemblies/{assembler}/{id}/{sub}/{id}.picked.fa",
        ok = "output/assemblies/mitoflex/{id}/{sub}/mitoflex.ok",
#	run = directory("assemblies/{assembler}/{id}/{sub}/MitoFlex")
    params:
        wd = os.getcwd(),
	outdir = "output/assemblies/mitoflex/{id}/{sub}",
        id = "{id}",
        clade = get_clade,
        genetic_code = get_code,
        optional = "--level debug"
    log:
        stdout = "output/assemblies/mitoflex/{id}/{sub}/stdout.txt",
        stderr = "output/assemblies/mitoflex/{id}/{sub}/stderr.txt"
    benchmark: "output/assemblies/mitoflex/{id}/{sub}/mitoflex.{id}.{sub}.benchmark.txt"
    threads: config["threads"]["mitoflex"] 
    singularity: "docker://samlmg/mitoflex:v0.2.9"
#    shadow: "minimal"
    shell:
        """
        cd {params.outdir}
        export HOME="{params.wd}/bin/MitoFlex"

        # run mitoflex - capture returncode, so if it fails, the pipeline won't stop 
        {params.wd}/bin/MitoFlex/MitoFlex.py all --workname MitoFlex --threads {threads} --fastq1 {params.wd}/{input.f} --fastq2 {params.wd}/{input.r} --genetic-code {params.genetic_code} --clade {params.clade} {params.optional} 1> {params.wd}/{log.stdout} 2> {params.wd}/{log.stderr} && returncode=$? || returncode=$?
        if [ $returncode -gt 0 ]
        then
            echo -e "\\n#### [$(date)]\\tmitoflex exited with an error - moving on - for details see: {params.wd}/{log.stderr}" 1>> {params.wd}/{log.stdout}
        fi
 
	#if the expected final assembly exists, get a copy
        if [ -f MitoFlex/MitoFlex.result/MitoFlex.picked.fa ]
        then
            cp MitoFlex/MitoFlex.result/MitoFlex.picked.fa {params.wd}/{params.outdir}/{wildcards.id}.mitoflex.{wildcards.sub}.fasta
        else
            echo -e "\\n#### [$(date)]\\tmitoflex did not pick a final assembly - moving on" 1>> {params.wd}/{log.stdout}
            touch {params.wd}/{params.outdir}/{wildcards.id}.mitoflex.{wildcards.sub}.fasta.missing 
        fi

        touch {params.wd}/{output.ok}
        """
