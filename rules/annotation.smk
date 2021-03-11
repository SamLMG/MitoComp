rule mitos_ref_db:
    output:
        "dbs/mitos/mitos.db.ok"
    threads: 1
    shell:
        """
	#download and untar to certain place
        wget -O dbs/mitos/mitos1-refdata.tar.bz2  https://zenodo.org/record/2683856/files/mitos1-refdata.tar.bz2
        tar -xf dbs/mitos/mitos1-refdata.tar.bz2 --directory dbs/mitos/
        rm dbs/mitos/mitos1-refdata.tar.bz2
	#make sure that the only directory in there will be renamed if need be
        if [ ! -d dbs/mitos/mitos1-refdata ]; then mv $(find dbs/mitos/ -maxdepth 1 -mindepth 1 -type d) dbs/mitos/mitos1-refdata; fi
        touch {output}
        """

rule mitos:
    input:
        "assemblies/{assembler}/{id}/{sub}/{assembler}.ok",
	rules.mitos_ref_db.output,
    output:
        done = "assemblies/{assembler}/{id}/{sub}/mitos.done"
    params:
        id = "{id}",
        fasta = "assemblies/{assembler}/{id}/{sub}/{id}.{assembler}.{sub}.fasta",
        seed = get_seed,
        genetic_code = get_code,
	sub = "{sub}",
	assembler = "{assembler}",
        wd = os.getcwd(),
        outdir = "assemblies/{assembler}/{id}/{sub}/annotation"
    log: 
        stdout = "assemblies/{assembler}/{id}/{sub}/stdout.txt",
        stderr = "assemblies/{assembler}/{id}/{sub}/stderr.txt"
    singularity:
        "docker://reslp/mitos:1.0.5"
    threads: config["threads"]["annotation"] 
    shell:
        """
	if [[ ! -d {params.outdir} ]]; then mkdir {params.outdir}; fi
	if [[ -f {params.fasta} ]]; then
	runmitos.py -i {params.fasta} -o {params.outdir} -r dbs/mitos/mitos1-refdata -c {params.genetic_code}
	else
        echo "Mitos could not be run because the input file is missing. Maybe the assembler did not produce output?" >> {log.stderr}
        fi
	touch {output.done}
	"""

rule annotation_stats:
    input:
        expand("assemblies/{assembler}/{{id}}/{sub}/mitos.done", id=IDS, sub=sub, assembler=Assembler)
    output:
        "compare/{id}/annotation/mitos/compare.mitos.{id}.done"
    shell:
        """
	touch {output}
        """
