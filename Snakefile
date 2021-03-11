import os
import pandas as pd

configfile: "data/config.yaml"
sample_data = pd.read_table(config["samples"], sep="\t").set_index("ID", drop=False)
#threads = pd.read_table(config["threads"], sep="\t").set_index("threads", drop=False)


#Assembler = ["getorganelle"] 
Assembler = ["norgal", "getorganelle", "mitoflex", "novoplasty", "mitobim"] 

#sub = [10000000, 20000000, "all"]
sub = [5000000]

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

localrules: all, setup_mitoflex_db, NOVOconfig, quast
rule all:
	input:
		expand(rules.annotation_stats.output, id=IDS, sub=sub, assembler=Assembler),
		expand(rules.align.output, id=IDS, sub=sub, assembler=Assembler)
