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
        "output/assemblies/{assembler}/{id}/{sub}/{assembler}.ok",
	rules.mitos_ref_db.output,
    output:
        done = "output/assemblies/{assembler}/{id}/{sub}/mitos.done"
    params:
        id = "{id}",
        fasta = "output/assemblies/{assembler}/{id}/{sub}/{id}.{assembler}.{sub}.fasta",
        genetic_code = get_code,
	sub = "{sub}",
	assembler = "{assembler}",
        wd = os.getcwd(),
        outdir = "output/assemblies/{assembler}/{id}/{sub}/annotation"
    log: 
        stdout = "output/assemblies/{assembler}/{id}/{sub}/annotation/stdout.txt",
        stderr = "output/assemblies/{assembler}/{id}/{sub}/annotation/stderr.txt"
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
        #rules.remove_newline.output
        expand("output/assemblies/{assembler}/{id}/{sub}/mitos.done", id=IDS, sub=sub, assembler=Assembler)
    output:
        starts = "output/compare/start_positions.txt",
        RC_assemblies = "output/compare/RC_assemblies.txt",
        done = "output/compare/annotation_stats.done"
    shell:
        """
        find ./output/assemblies/ -maxdepth 4 -name "*.fasta" | cat > output/compare/assembly_paths.txt
        find ./output/assemblies/ -name "result.bed" | cat > output/compare/bed_paths.txt
        scripts/annotate.py output/compare/bed_paths.txt output/compare/assembly_paths.txt output/compare/Genes.txt
        scripts/roll_prep.py output/compare/Genes.txt output/compare/bed_paths.txt output/compare/MFG_assemblies.txt output/compare/No_MFG_assemblies.txt output/compare/start_positions.txt output/compare/RC_assemblies.txt output/compare/forward_assemblies.txt
        touch {output.done}
        """
