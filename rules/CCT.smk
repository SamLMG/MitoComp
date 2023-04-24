rule gbk_prep:
    input:
        rules.gene_positions.output
    output:
        "output/{id}/annotation/compare/CCT/{id}.{sub}.{assembler}.gbk.done"
    params:
        id = "{id}",
        assembler = "{assembler}",
        sub = "{sub}",
        gff = "output/{id}/annotation/second_mitos/{id}.{sub}.{assembler}/result.gff",
        gff_NoMFG = "output/{id}/annotation/second_mitos/{id}.{sub}.{assembler}/result.gff",
        gbk = "output/{id}/annotation/compare/CCT/{id}.{sub}.{assembler}.genbank",
        outdir = "output/{id}/annotation/compare/CCT/" 
    singularity: 
        "docker://pegi3s/emboss:6.6.0"
    shell:
        """
        if [ -f output/{params.id}/annotation/alignment/clustalo/{params.id}.{params.sub}.{params.assembler}.rolled.*.fasta ]
        then
        seqret -sequence output/{params.id}/annotation/alignment/clustalo/{params.id}.{params.sub}.{params.assembler}.rolled.*.fasta -outseq {params.gbk} -feature -fformat gff -fopenfile {params.gff} -osformat genbank -auto
        sed -i '1 a ACCESSION   {params.id}.{params.sub}.{params.assembler}' {params.gbk}
        sed -i 's/gene/CDS/g' {params.gbk}
        sed -i 's/*Name //g' {params.gbk}
        sed -i 's/([^()]*)//g' {params.gbk}
        sed -i '/*/d' {params.gbk}
        elif [ -f output/{params.id}/assemblies/{params.sub}/{params.assembler}/{params.id}.{params.sub}.{params.assembler}.fasta ]
        then 
        seqret -sequence output/{params.id}/assemblies/{params.sub}/{params.assembler}/{params.id}.{params.sub}.{params.assembler}.fasta -outseq {params.gbk} -feature -fformat gff -fopenfile {params.gff_NoMFG} -osformat genbank -auto
        sed -i '1 a ACCESSION   {params.id}.{params.sub}.{params.assembler}' {params.gbk}
        sed -i 's/gene/CDS/g' {params.gbk}
        sed -i 's/*Name //g' {params.gbk}
        sed -i 's/([^()]*)//g' {params.gbk}
        sed -i '/*/d' {params.gbk}
        fi
        touch {output}
        """

rule CCT:
    input:
        "output/{id}/annotation/compare/CCT/{id}.{sub}.{assembler}.gbk.done"
    output:
        "output/{id}/annotation/compare/CCT/{id}.{sub}.{assembler}.CCT.done",
    params:
        id = "{id}",
        assembler = "{assembler}",
        sub = "{sub}",
        outdir = "output/{id}/annotation/compare/CCT",
        wd = os.getcwd()
    singularity:
        "docker://pstothard/cgview_comparison_tool:1.0.1"
    shell:
        """
        set +o pipefail;
        length=$(awk -F'\t' '{{if ($1 == "{params.id}" && $2 == "{params.sub}" && $3 == "{params.assembler}" && $4 > 1000){{print $4;}}}}' output/stats/Genes.txt)
        if [ -f output/{params.id}/annotation/compare/CCT/{params.id}.{params.sub}.{params.assembler}.genbank ] && [ $length -gt 1000 ]
        then
            cd {params.outdir}
            build_blast_atlas.sh -i {params.id}.{params.sub}.{params.assembler}.genbank && returncode=$? || returncode=$? #> /dev/null 2>&1 
            echo $returncode
            if [[ $returncode -eq 0 ]]
            then
                cp {params.id}*.genbank {params.id}.{params.sub}.{params.assembler}/comparison_genomes/
                build_blast_atlas.sh -p {params.id}.{params.sub}.{params.assembler} -z medium --custom "arrowheadLength=12 blast_divider_ruler=T blastRulerColor=green draw_divider_rings=T backboneColor=green global_label=T legend=T use_opacity=F backboneRadius=900 labelFontSize=60 borderColor=white width=3000 height=3000 gc_content=T backboneThickness=0.01 gcColorNeg=blue gcColorPos=red legendFontSize=30 featureThickness=50 _cct_blast_thickness=25.00000 useInnerLabels=false" && returncode=$? || returncode=$? #> /dev/null 2>&1
                echo $returncode
                if [[ $returncode -eq 0 ]]
                then
                    redraw_maps.sh -p {params.id}.{params.sub}.{params.assembler} -f svg
                else
                    echo "There was an Error in the second CCT command."
                    touch {params.wd}/{params.outdir}/{params.id}.{params.sub}.{params.assembler}.CCTmap.missing
                fi
            else
                echo "There was an Error in the first CCT command."
                touch {params.wd}/{params.outdir}/{params.id}.{params.sub}.{params.assembler}.CCTmap.missing
            fi
        else
            touch {params.outdir}/{params.id}.{params.sub}.{params.assembler}.CCTmap.missing
        fi
        #if the expected final assembly exists, get a copy
        if [ -f {params.id}.{params.sub}.{params.assembler}/maps_for_dna_vs_dna/dna_vs_dna_medium.svg ]
        then
            cp {params.id}.{params.sub}.{params.assembler}/maps_for_dna_vs_dna/dna_vs_dna_medium.svg {params.id}.{params.sub}.{params.assembler}.map.svg 
            cp {params.id}.{params.sub}.{params.assembler}/maps_for_dna_vs_dna/dna_vs_dna_medium.png {params.id}.{params.sub}.{params.assembler}.map.png 
        else
            echo -e "\\n#### [$(date)]\\tCCT did not produce an assembly map. Either no assembly was found or it was under 1000bp" 
            touch {params.wd}/{params.outdir}/{params.id}.{params.sub}.{params.assembler}.CCTmap.missing
        fi
        touch {params.wd}/{output}
        """
