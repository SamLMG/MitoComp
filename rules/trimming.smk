rule trimmomatic:
    input:
        f = rules.fastqdump.output.f,
        r = rules.fastqdump.output.r
#    resources:
#        qos="normal_binf -C binf",
#        partition="binf",
#        mem="100G",
#        name="trimmomatic",
#        nnode="-N 1"
    output:
        fout = "trimmed/{id}_1P_trim.fastq.gz",
        funp = "trimmed/{id}_1P_unpaired.fastq.gz",
        rout = "trimmed/{id}_2P_trim.fastq.gz",
        runp = "trimmed/{id}_2P_unpaired.fastq.gz",
        ok = "trimmed/trim_{id}.ok"
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
