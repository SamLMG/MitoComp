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

if os.environ["RUNMODE"] == "all" or os.environ["RUNMODE"] == "assembly":
	rule gather:
		input:
			#rules.get_organelle.output,
			#rules.MITObim.output,
			#rules.norgal.output,
			#rules.NOVOplasty.output,
			#rules.mitoflex.output,
			expand("output/{id}/assemblies/{sub}/{assembler}/{assembler}.ok", id=IDS, sub=sub, assembler=Assembler),
			#gather_assemblies,
			#expand("output/gathered_assemblies/{id}.{sub}.{assembler}.fasta", id=IDS, sub=sub, assembler=Assembler)
		output:
			"output/gathered_assemblies/gather.done" 
		shell:
			"""
                        #cp {input} output/gathered_assemblies/
			touch {output}
			"""

elif os.environ["RUNMODE"] == "annotate":
	rule gather:
		input:
			gather_assemblies	
		output:
			"output/gathered_assemblies/gather.done"
		shell:
			"""
			touch {output}
			"""

rule mitos:
    input:
        rules.gather.output,
	rules.mitos_ref_db.output,
    output:
        done = "output/{id}/annotation/mitos/{id}.{sub}.{assembler}.mitos.done"
    params:
        id = "{id}",
        fasta = "output/gathered_assemblies/{id}.{sub}.{assembler}.fasta",
        genetic_code = get_code,
	sub = "{sub}",
	assembler = "{assembler}",
        wd = os.getcwd(),
        outdir = "output/{id}/annotation/mitos/{id}.{sub}.{assembler}"
    log: 
        stdout = "output/{id}/annotation/mitos/{id}.{sub}.{assembler}/stdout.txt",
        stderr = "output/{id}/annotation/mitos/{id}.{sub}.{assembler}/stderr.txt"
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

if os.environ["RUNMODE"] == "all" or os.environ["RUNMODE"] == "assembly":
	rule annotation_stats:
	    input:
	        expand("output/{id}/annotation/mitos/{id}.{sub}.{assembler}.mitos.done", id=IDS, sub=sub, assembler=Assembler)
	    output:
	        starts = "output/stats/start_positions.txt",
	        RC_assemblies = "output/stats/RC_assemblies.txt",
	        done = "output/stats/annotation_stats.done",
	    shell:
	        """
	        find ./output/*/assemblies/ -maxdepth 3 -name "*.fasta" | cat > output/stats/assembly_paths.txt
	        find ./output/*/annotation/ -name "result.bed" | cat > output/stats/bed_paths.txt
	        scripts/annotate.py output/stats/bed_paths.txt output/stats/assembly_paths.txt output/stats/Genes.txt
	        scripts/roll_prep.py output/stats/Genes.txt output/stats/bed_paths.txt output/stats/MFG_assemblies.txt output/stats/No_MFG_assemblies.txt output/stats/start_positions.txt output/stats/RC_assemblies.txt output/stats/forward_assemblies.txt
	        touch {output.done}
	        """
elif os.environ["RUNMODE"] == "annotate":
	rule annotation_stats:
	    input:
	        expand("output/{id}/annotation/mitos/{id}.{sub}.{assembler}.mitos.done", zip, id=IDS, sub=sub, assembler=Assembler)
	    output:
	        starts = "output/stats/start_positions.txt",
	        RC_assemblies = "output/stats/RC_assemblies.txt",
	        done = "output/stats/annotation_stats.done",
	    shell:
	        """
	        find ./output/*/assemblies/ -maxdepth 3 -name "*.fasta" | cat > output/stats/assembly_paths.txt
	        find ./output/*/annotation/ -name "result.bed" | cat > output/stats/bed_paths.txt
	        scripts/annotate.py output/stats/bed_paths.txt output/stats/assembly_paths.txt output/stats/Genes.txt
	        scripts/roll_prep.py output/stats/Genes.txt output/stats/bed_paths.txt output/stats/MFG_assemblies.txt output/stats/No_MFG_assemblies.txt output/stats/start_positions.txt output/stats/RC_assemblies.txt output/stats/forward_assemblies.txt
	        touch {output.done}
	        """
