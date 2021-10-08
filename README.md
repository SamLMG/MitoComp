# MitoComp – A mitochondrial genome assembley, annotation and comparison pipeline.

The MitoComp pipeline is designed with two distinct aims. First, to provide a robust and user-friendly approach to assembling mitochondrial genomes from short-read WGS using five third-party, command-line based assembly tools. Second, MitoComp aims to provide an objective comparison of these assembly tools and how they work with different datasets. A rulegraph outlining the steps MitoComp takes is shown below.

WGS data is first provided by the user in one of two ways: i) by specifying the path to local reads in fastq.gz format or ii) providing the accession number of a short-read archive (SRA) of public data from genbank and downloading it in fastq.gz format using the fastqdump tool ([https://github.com/ncbi/sra-tools](https://github.com/ncbi/sra-tools)). MitoComp then trims ([https://github.com/timflutre/trimmomatic](https://github.com/timflutre/trimmomatic)) , subsamples ([https://github.com/lh3/seqtk](https://github.com/lh3/seqtk)), and interleaves ([https://github.com/BioInfoTools/BBMap](https://github.com/BioInfoTools/BBMap)) the datasets prior to assembling mitogenomes using:

- Mitoflex ([https://github.com/Prunoideae/MitoFlex](https://github.com/Prunoideae/MitoFlex))
- GetOrganelle ([https://github.com/Kinggerm/GetOrganelle](https://github.com/Kinggerm/GetOrganelle))
- NOVOplasty ([https://github.com/ndierckx/NOVOPlasty](https://github.com/ndierckx/NOVOPlasty))
- Norgal ([https://bitbucket.org/kosaidtu/norgal/src/master/](https://bitbucket.org/kosaidtu/norgal/src/master/))
- MITObim ([https://github.com/chrishah/MITObim](https://github.com/chrishah/MITObim))

The user may of course choose to use just one, all or any combination of these assemblers. Furthermore, the user may choose to the level to which the raw data are subsampled or instead choose to skip this step and use the entire dataset. The resulting assemblies are then annotated via MITOS ([https://gitlab.com/Bernt/MITOS](https://gitlab.com/Bernt/MITOS)) and aligned with one another for evaluation of inconsistencies between algorithms and A comparison with regards to speed, CPU usage, quality and annotation completeness is performed. MitoComp uses the pipeline management system Snakemake with all software tools containerized via Docker/Singularity.

## Obtaining and running MitoComp

MitoComp is primarily designed to run on HPC clusters using either a SGE or SLURM job scheduling system. It may also be run on a desktop computer using Linux but due to the computationally intensive nature of many of the steps involved, this is not optimal. Other than this MitoComp&#39;s only prerequisites are:

1. A singularity installation (tested with singularity version 3.5.2)
2. A snakemake installation (tested with snakemake 6.0.2; snakemake can be installed through conda using the following commands)

```
conda install -c conda-forge mamba

mamba create -c conda-forge -c bioconda -n snakemake snakemake
```
```
conda activate snakemake
```

The user should first clone this repository to their local computer. To do this use the following command.

```
git clone --recursive https://github.com/SamLMG/MitoComp.git
```

## Downloading adapter sequences

The trimming rule of this pipeline removes adapter sequences from raw reads. The relevant adapters should be downloaded from https://github.com/usadellab/Trimmomatic/tree/main/adapters and placed in a directory called &quot;adapterseq&quot; Inside the MitoComp directory. This may be done using the following commands depending on the required adapter. 

```
mkdir adapterseq
```

```
wget https://raw.githubusercontent.com/usadellab/Trimmomatic/main/adapters/TruSeq3-PE.fa
```

## Setting up the analysis

The `data/data.csv` file should be edited to correspond to the user&#39;s datasets. The columns in this file are named as follows:

```
ID,forward,reverse,seed,SRA,Clade,Code,novoplasty_kmer,Read_length,Adapter,Type,GO_Rounds
```

- ID: This column refers to the name of the sample and may be freely completed by the user but we advise against the use of most special characters including &quot;.&quot; and instead advise users to use &quot;_&quot;
- forward, reverse: If the user wishes to provide their own WGS data, the paths to both forward and reverse reads should be provided in the corresponding columns. These reads should be in fastq format and gzipped.
- seed: For the assemeblers MITObim, NOVOplasty and GetOrganelle a seed sequence from the species in question is required. This may be any mitochondrial sequence but in most cases the coxI gene is used. The path to this seed should be specified in the seed column. This may be done using entrez-direct (which may be installed via conda) and executing the following command where the -query corresponds to the sequence's accession number and filename is defined by the user.

```
esearch -db nucleotide -query "MF420392.1" | efetch -format fasta > seeds/D.rerio_coxI.fasta
```
- SRA: MitComp can automatically download read data from NCBI SRA. Enter an SRA accession number here to do so.
- Clade: Some of the assemblers require the clade (e.g. phylum) of the chosen species which should be entered in the clade column.
- Code: Some of the assemblers and MITOS require the genetic code of the chosen species which should be entered in the clade column. A list of genetic codes may be found here [https://www.ncbi.nlm.nih.gov/Taxonomy/Utils/wprintgc.cgi?mode=c](https://www.ncbi.nlm.nih.gov/Taxonomy/Utils/wprintgc.cgi?mode=c)
- novoplasty_kmer: Novoplasty requires a k-mer length for assembly. Provide an uneven number here.
- Read_length: Length of the provided reads. This is used for trimming.
- Adapter: To perform adapter trimming, a relative path to a file with known adapter sequences should be provided here. These may be downloaded from [https://github.com/usadellab/Trimmomatic/tree/main/adapters]
- Type: For novoplasty and GetOrganelle it is necessary to provide a database type here. Possible values are: 'embplant_pt', 'other_pt', 'embplant_mt', 'embplant_nr', 'animal_mt', 'fungus_mt', 'anonym', or a combination of above split by comma(s). Please note that Mitoflex is primarily designed for animal mitogenome assembly. As a result non-animal datasets will most likely fail to produce an assembly. 
- GO_Rounds: This indicates the number of rounds of extension GetOrganelle will complete in order to recruit target-associated reads from the dataset. We recommend using 10 but this figure may need to be raised for lower coverage datasets. 

The user may also choose to edit the config file (data/config.yaml). This allows different combinations of assemblers to be used by removing them from a list. By default, this is set to use all five assemblers:

```
Assembler = ["norgal", "getorganelle", "mitoflex", "novoplasty", "mitobim"]
```
The user may however, only want to use norgal, in which case they would set this to:

```
Assembler = ["norgal"]
```

Or they may wish to use both norgal and MITObim:

```
Assembler = ["norgal", "mitobim"]
```

Etc.

Furthermore, the level of subsampling can be set in a similar manner by editing the sub list.

For example, the following sub list will subsample the datasets thrice: with 5, 10 and 20 million randomly selected reads.

```
sub = [5000000, 10000000, 20000000]
```
The number of threads given to each rule can be set by the user in the config file. For instance,

```
threads:
   download: 2
   trimming: 24
```

will provide 2 threads for the download rule and 24 threads to the trimming rule.

Some further parameters for the trimming rule are also specified in this file and may be edited by the user

We also provide users working on a cluster with a template cluster config file for clusters using either a SLURM or a SGE submission system. Resources provided to each job as well as the paths to log files may be set here by the user according to their cluster settings.

The following command uses the MitoComp script to run the pipeline on a SLURM system:

```
./MitoComp -t slurm -c data/cluster-config-SLURM.yaml.template
```

Or on an SGE system:

```
./MitoComp -t sge -c data/cluster-config-SGE.yaml.template
```

We advise adding the `--dry` option to this command first. This will not submit any jobs but will print jobs to be completed and flag up any errors.

We provide MitoComp two alternate runmodes. These are specified via the -m flag. This determines how far the pipeline should run. For assembly and an initial annotation, specify "-m assembly". For a complete run, specify "-m all" or ignore this option. For example the following command will run in assembly mode: 

```
./MitoComp -m assembly -t slurm -c data/cluster-config-SLURM.yaml.template
```

Finally, it may occur that one step of the pipeline fails causing subsequent jobs to remain in the queuing system indefinately. This may prevent other jobs from running. The following command will kill all jobs that are depend on this specific instance of MitoComp without affecting other jobs running on the cluster:

```
./MitoComp --reset -t slurm
```

A rulegraph showing the order in which jobs will run is shown below:

![Order of jobs](rulegraph.svg)
