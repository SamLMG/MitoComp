def trimin_forward(wildcards):
        if sample_data.loc[(wildcards.id), ["SRA"]].any():
            return "output/{id}/reads/downloaded_reads/"+wildcards.id+"_1.fastq.gz"
        else:
            return "output/{id}/reads/local_reads/"+wildcards.id+"_1.fastq.gz"
def trimin_reverse(wildcards):
        if sample_data.loc[(wildcards.id), ["SRA"]].any():
            return "output/{id}/reads/downloaded_reads/"+wildcards.id+"_2.fastq.gz"
        else:
            return "output/{id}/reads/local_reads/"+wildcards.id+"_2.fastq.gz"

        


rule trimmomatic:
    input:
        f = trimin_forward,
        r = trimin_reverse
    output:
        fout = "output/{id}/reads/trimmed/{id}_1P_trim.fastq.gz",
        funp = "output/{id}/reads/trimmed/{id}_1P_unpaired.fastq.gz",
        rout = "output/{id}/reads/trimmed/{id}_2P_trim.fastq.gz",
        runp = "output/{id}/reads/trimmed/{id}_2P_unpaired.fastq.gz",
        ok = "output/{id}/reads/trimmed/trim_{id}.ok"
    params:
        adapter = get_adapter,
        minlength = config["trimming"]["minlength"],
        windowsize = config["trimming"]["windowsize"],
        stepsize = config["trimming"]["stepsize"],
        quality = config["trimming"]["quality"],
        required_quality = config["trimming"]["required_quality"],
        seed_mismatches = config["trimming"]["seed_mismatches"],
        palindrome_clip = config["trimming"]["palindrome_clip"],
        simple_clip = config["trimming"]["simple_clip"]
    threads: config["threads"]["trimming"] 
    singularity: 
        "docker://reslp/trimmomatic:0.38"
    shell:
        """
        if [[ ! -f {params.adapter} ]]; then
            echo "Adpater file not found. Please check your config files." >&2
            exit 1
        fi
        trimmomatic PE -threads {threads} {input.f} {input.r} {output.fout} {output.funp} {output.rout} {output.runp} ILLUMINACLIP:{params.adapter}:{params.seed_mismatches}:{params.palindrome_clip}:{params.simple_clip} LEADING:{params.quality} TRAILING:{params.quality} SLIDINGWINDOW:{params.windowsize}:{params.required_quality} MINLEN:{params.minlength}
        touch {output.ok}
        """
