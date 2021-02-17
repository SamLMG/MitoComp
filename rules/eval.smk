rule quast:
    input:
        expand("assemblies/{assembler}/{id}/{sub}/{assembler}.ok", id=IDS, sub=sub, assembler=Assembler)
	
#        norgal = expand("assemblies/{assembler}/{id}/{sub}/{id}_{assembler}", sub=sub, id = IDS,  assembler = Assembler[0]),
##        norgal = rules.norgal.output,
#        MitoFlex = expand("assemblies/{assembler}/{id}/{sub}/{id}.picked.fa", sub=sub, id = IDS, assembler = Assembler[1]),
##        Mitoflex = rules.mitoflex.output.fasta,
#        GetOrganelle = expand("assemblies/{assembler}/{id}/{sub}/{id}.getorganelle.final.fasta", sub=sub, id = IDS, assembler = Assembler[2]),
##        GetOrganelle = rules.get_organelle.output,
#        Novoplasty = expand("assemblies/{assembler}/{id}/{sub}/Circularized_assembly_1_{id}_{sub}_novoplasty.fasta", sub=sub, id = IDS, assembler = Assembler[3]),
##        Novoplasty = rules.NOVOplasty.output,
#        MITObim = expand("assemblies/{assembler}/{id}/{sub}/{id}_{assembler}_coxI.fasta", sub=sub, id = IDS, assembler = Assembler[4])
##        MITObim = rules.MITObim.output
    output:
        "QUAST/report.tsv"
    params:
        outdir = "QUAST/",
#    conda:
#        "envs/quast.yml"
    threads: 1
    singularity: "docker://reslp/quast:5.0.2"
    shell:
        """
        quast -o {params.outdir} {input}
        """
