import os
import pandas as pd

configfile: "data/config.yaml"
sample_data = pd.read_table(config["samples"], sep=",").set_index("ID", drop=False)

include: "rules/functions.smk"
include: "rules/download.smk"
include: "rules/trimming.smk"
include: "rules/subsample.smk"
include: "rules/norgal.smk"
include: "rules/getorganelle.smk"
include: "rules/mitoflex.smk"
include: "rules/novoplasty.smk"
include: "rules/mitobim.smk"
include: "rules/annotation.smk"
include: "rules/alignment.smk"
include: "rules/annotationII.smk"
include: "rules/CCT.smk"
include: "rules/report.smk"


rule all:
    input:
        "output/report/report.html"
rule assembly_only:
    input:
        expand("output/{id}/assemblies/{sub}/{assembler}/{assembler}.ok", id=IDS, sub=sub, assembler=Assembler)
