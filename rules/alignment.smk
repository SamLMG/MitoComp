rule roll:
    input:
        rules.annotation_stats.output,
    output:
         "output/stats/roll.done"
    singularity:
        "docker://python:2.7.18-stretch"
    shell:
        """
        while read first rest 
            file=$first
            position=$rest
            prefix1=$(echo $first | cut -d "/" -f3 | cut -d "." -f 1)
            prefix2=$(echo $first | cut -d "/" -f3 | cut -d "." -f 1-3)
        do
            if [[ $first == "" ]]; then
                break
            fi
            if [[ ! -d output/$prefix1/annotation/alignment/ ]]; then
                mkdir output/$prefix1/annotation/alignment/
            fi
            scripts/circules.py -f $file -n $position -p output/$prefix1/annotation/alignment/$prefix2
        if [[ ! -f output/$prefix1/annotation/alignment/$prefix2.rolled.$position.fasta ]]
        then
            cp $file output/$prefix1/annotation/alignment/$prefix2.rolled.$position.fasta
        fi
        sed -i "s#>.*#>$file#g" output/$prefix1/annotation/alignment/$prefix2.rolled.$position.fasta
        done < output/stats/start_positions.txt
        touch {output}
        """

###some assemblies orientated in reverse complement so should be reversed
rule reverse_complement:
    input:
        rules.roll.output,
        RC_assemblies = "output/stats/RC_assemblies.txt"
    output:
        "output/{id}/annotation/alignment/RC.done"
    singularity:
        "docker://python:3.7"
    params:
        id = "{id}"
    shell:
        """
        mkdir -p output/{params.id}/annotation/alignment/clustalo
        scripts/RComp.py {params.id}
        touch {output}
        """


rule align:
    input:
        rules.reverse_complement.output
    output:
        "output/{id}/annotation/alignment/clustalo/{id}.align.done"
    params:
        id = "{id}"
    singularity: "docker://reslp/clustalo:1.2.4" 
    threads: config["threads"]["alignment"]
    shell:
        """
	cd output/{params.id}/annotation/alignment
	# cp has to fail silently of no RC file is found
        if [[ $(find {params.id}.*.rolled*.fasta) ]]; then
            cp {params.id}.*.rolled*.fasta clustalo/ 2>/dev/null || :
            cd clustalo
            for file in $(find *_RC.fasta); do 
		rm -f $(echo $file | sed 's/_RC//')
	    done
            no_assemblies=$(find {params.id}.*.rolled*.fasta | wc -l)
	    if [[ "$no_assemblies" -gt 1 ]]; then 
	    	cat {params.id}*.fasta > all_{params.id}_assemblies.fasta
            	clustalo -i all_{params.id}_assemblies.fasta -o {params.id}_alignment.fa --threads={threads}
            	touch {params.id}.align.done
	    else
		echo "There is only a single assembly for this ID so cannot align"
		touch {params.id}.align.done
	    fi
        else
            echo "Align could not be run because the input file is missing. This may happen when the assembler did not produce output or when MITOS did not find the most found gene in this assembly. This may also occur if there is only a single assembly for this ID"
            cd ../../../../
            touch {output}
        fi
        """
