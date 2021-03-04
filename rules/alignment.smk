rule roll:
    input:
        expand("assemblies/{assembler}/{{id}}/{sub}/mitos.done", id=IDS, sub=sub, assembler=Assembler)
    output:
        "compare/{id}/alignment/muscle/arrange.{id}.done"
    shell:
        """
	touch {output}
        """

rule align:
    input:
        rules.roll.output
    output:
        "compare/{id}/alignment/muscle/muscle.{id}.done"
    singularity: "docker://reslp/clustalo:1.2.4" 
    threads: config["threads"]["alignment"]
    shell:
        """
	touch {output}
        """
