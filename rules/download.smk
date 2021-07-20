rule fastqdump:
	params:
		accession = get_accession,
                f = get_forward,
                r = get_reverse,
                wd = os.getcwd()
	output:
		f = "raw_mt_reads/{id}_1.fastq.gz",
		r = "raw_mt_reads/{id}_2.fastq.gz"
#	resources:
#		qos="normal_0064",
#		partition="mem_0064",
#		mem="10G",
#		name="fastq-dump",
#		nnode="-N 1"
	singularity:
                "docker://reslp/sra-tools:2.10.9"
	threads: config["threads"]["download"] 
	shadow: "shallow"
	shell:
		"""
		# configuration of sra-tools is messed up in singularity. This is connected with these issues:
		# https://github.com/ncbi/sra-tools/issues/291
		# https://standage.github.io/that-darn-cache-configuring-the-sra-toolkit.html
		mkdir -p $HOME/.ncbi
		printf '/LIBS/GUID = "%s"\\n' `uuidgen` > $HOME/.ncbi/user-settings.mkfg
                mkdir -p $HOME/tmp
		echo "/repository/user/main/public/root = \'$HOME/tmp\'" >> $HOME/.ncbi/user-settings.mkfg

		if [[ -f "{params.f}" ]] && [[ -f "{params.r}" ]]; then 
                    ln -s ../{params.f} {params.wd}/{output.f}
                    ln -s ../{params.r} {params.wd}/{output.r}
                    echo "using local fastq.gz files"
                elif [[ "nan" != "{params.accession}" ]]; then
                    prefetch --max-size 1024000000 {params.accession}
		    fastq-dump --split-files --gzip --defline-seq '@$ac-$sn/$ri' {params.accession}
		    mv {params.accession}_1.fastq.gz {output.f}
		    mv {params.accession}_2.fastq.gz {output.r}
		    echo "no local files, downloading SRA"
                fi
                """
