rule fastqdump:
	params:
		accession = get_accession,
                wd = os.getcwd()
	output:
		f = "output/{id}/reads/downloaded_reads/{id}_1.fastq.gz",
		r = "output/{id}/reads/downloaded_reads/{id}_2.fastq.gz"
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
		echo "no local files, downloading from SRA: {params.accession}"
		mkdir -p $HOME/.ncbi
		printf '/LIBS/GUID = "%s"\\n' `uuidgen` > $HOME/.ncbi/user-settings.mkfg
                mkdir -p $HOME/tmp
		echo "/repository/user/main/public/root = \'$HOME/tmp\'" >> $HOME/.ncbi/user-settings.mkfg

		#remove remnants of previous aborted downloads		
		if [ $(find ./tmp/sra -name "{params.accession}*" | wc -l) -gt 0 ]; then rm tmp/sra/{params.accession}*; fi

		# download
		prefetch --max-size 1024000000 {params.accession}
		fastq-dump --split-files --gzip --defline-seq '@$ac-$sn/$ri' --defline-qual '+' {params.accession}  

#		# cleanup
#		rm tmp/sra/{params.accession}.sra

		#rename to expected output files
		mv {params.accession}_1.fastq.gz {output.f}
		mv {params.accession}_2.fastq.gz {output.r}

		# cleanup
		rm tmp/sra/{params.accession}.sra
        """

rule prep_local_reads:
	input:
                f = get_forward,
                r = get_reverse
	params:
                wd = os.getcwd()
	output:
		f = "output/{id}/reads/local_reads/{id}_1.fastq.gz",
		r = "output/{id}/reads/local_reads/{id}_2.fastq.gz"
	threads: 1
	shell:
		"""
		if [[ -f "{params.wd}/{input.f}" ]] && [[ -f "{params.wd}/{input.r}" ]]; then 
                    echo "using local fastq.gz files"
                    ln -s {params.wd}/{input.f} {output.f}
                    ln -s {params.wd}/{input.r} {output.r}
		fi
		"""
