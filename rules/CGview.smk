rule gbk_prep:
    input:
        rules.gene_positions.output
#        fasta = "compare/alignment/clustalo/{id}.{assembler}.{sub}.rolled.12476_RC.fasta",
#        gff = "compare/alignment/mitos2/{id}.{sub}.{assembler}/result.gff"
    output:
        "compare/CGview/{id}.{assembler}.{sub}.gbk.done"
    params:
        id = "{id}",
        assembler = "{assembler}",
        sub = "{sub}",
        gff = "compare/alignment/mitos2/{id}.{sub}.{assembler}/result.gff",
        gbk = "compare/CGview/{id}.{assembler}.{sub}.genbank",
        outdir = "compare/alignment/mitos2/{id}.{sub}.{assembler}" 
#    resources:
#        qos="normal_0064",
#        partition="mem_0064",
#        mem="10G",
#        name="interleave",
#        nnode="-N 1"
    singularity: 
        "docker://pegi3s/emboss"
    shell:
        """
        seqret -sequence compare/alignment/clustalo/{params.id}.{params.assembler}.{params.sub}.rolled.*.fasta -outseq {params.gbk} -feature -fformat gff -fopenfile {params.gff} -osformat genbank -auto
        sed -i 's/gene/CDS/g' {params.gbk}
        sed -i 's/*Name //g' {params.gbk}
        sed -i 's/([^()]*)//g' {params.gbk}
        sed -i '/*/d' {params.gbk}
        touch {output}
        """

rule CGview:
    input:
        rules.gbk_prep.output
    output:
        "compare/CGview/{id}.{assembler}.{sub}.cgview.done"
    params:
        id = "{id}",
        assembler = "{assembler}",
        sub = "{sub}"
    singularity:
        "docker://pstothard/cgview"
    shell:
        """
        perl /usr/bin/cgview_xml_builder.pl -sequence getorganelle.genbank -gc_content T -gc_skew T -size large-v2 -tick_density 0.05 -draw_divider_rings T -custom showBorder=false title="{params.id}.{params.assembler}.{params.sub} map" titleFontSize="200" -feature_labels T -output {params.id}.{params.assembler}.{params.sub}.map.xml
        java -jar /usr/bin/cgview.jar -i map.xml -o {params.id}.{params.assembler}.{params.sub}.map.svg
        touch {output}
        """  
