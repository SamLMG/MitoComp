import os
import pandas as pd

configfile: "data/config.yaml"
sample_data = pd.read_table(config["samples"], sep="\t").set_index("ID", drop=False)
#threads = pd.read_table(config["threads"], sep="\t").set_index("threads", drop=False)


Assembler = config["Assembler"] 
#Assembler = ["norgal", "getorganelle", "mitoflex", "novoplasty", "mitobim"] 

#sub = [5000000, 10000000, 20000000, "all"]
sub = config["sub"]

include: "rules/functions.smk"
include: "rules/download.smk"
include: "rules/trimming.smk"
include: "rules/subsample.smk"
include: "rules/norgal.smk"
include: "rules/getorganelle.smk"
include: "rules/mitoflex.smk"
include: "rules/novoplasty.smk"
include: "rules/mitobim.smk"
include: "rules/eval.smk"
include: "rules/annotation.smk"
include: "rules/alignment.smk"
include: "rules/annotationII.smk"
include: "rules/CCT.smk"
include: "rules/report.smk"


localrules: all, setup_mitoflex_db, NOVOconfig, quast, gene_positions, gbk_prep, CCT, annotation_stats
rule all:
	input:
####                expand("trimmed/trim_{id}.ok", id=IDS, sub=sub, assembler=Assembler),
####                expand("assemblies/{assembler}/{id}/{sub}/{assembler}.ok", id=IDS, sub=sub, assembler=Assembler),
####		expand(rules.annotation_stats.output, id=IDS, sub=sub, assembler=Assembler),
####		expand(rules.second_mitos.output, id=IDS, sub=sub, assembler=Assembler),
####                expand(rules.align.output, id=IDS, sub=sub, assembler=Assembler),
####                "compare/alignment/mitos2/gene_positions.done",
####		expand(rules.CCT.output, id=IDS, sub=sub, assembler=Assembler)
####                expand("compare/CGview/{id}.{assembler}.{sub}.cgview.done", id=IDS, sub=sub, assembler=Assembler)
####                expand("compare/CCT/{id}.CCT.done", id=IDS) 
		"report/report.html"
