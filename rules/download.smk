rule fastqdump:
	params:
		accession = get_accession
	output:
		f = "raw_mt_reads/{id}_1.fastq.gz",
		r = "raw_mt_reads/{id}_2.fastq.gz"
#	resources:
#		qos="normal_0064",
#		partition="mem_0064",
#		mem="10G",
#		name="fastq-dump",
#		nnode="-N 1"
	conda: "envs/sra-tools.yml"
	threads: 2
	shadow: "minimal"
	shell:
		"""
		prefetch --max-size 1024000000 {params.accession}
		fastq-dump --split-files --gzip --defline-seq '@$ac-$sn/$ri' {params.accession}
		mv {params.accession}_1.fastq.gz {output.f}
		mv {params.accession}_2.fastq.gz {output.r}
		"""
