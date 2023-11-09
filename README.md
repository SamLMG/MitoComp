# MitoComp – A mitochondrial genome assembley, annotation and comparison pipeline.

The MitoComp pipeline is designed with two distinct aims. First, to provide a robust and user-friendly approach to assembling mitochondrial genomes from short-read WGS using five third-party, command-line based assembly tools. Second, MitoComp aims to provide an objective comparison of these assembly tools and how well they work with different datasets. A rulegraph outlining the steps MitoComp takes is shown below.

WGS data is first provided by the user in one of two ways: i) by specifying the path to local reads in fastq.gz format or ii) providing the accession number of a short-read archive (SRA) of public data from genbank and downloading it in fastq.gz format using the fastqdump tool ([https://github.com/ncbi/sra-tools](https://github.com/ncbi/sra-tools)). MitoComp then trims ([https://github.com/timflutre/trimmomatic](https://github.com/timflutre/trimmomatic)), subsamples ([https://github.com/lh3/seqtk](https://github.com/lh3/seqtk)), and interleaves ([https://github.com/BioInfoTools/BBMap](https://github.com/BioInfoTools/BBMap)) the datasets prior to assembling mitogenomes using the the five following assembly programs:

- Mitoflex ([https://github.com/Prunoideae/MitoFlex](https://github.com/Prunoideae/MitoFlex))
- GetOrganelle ([https://github.com/Kinggerm/GetOrganelle](https://github.com/Kinggerm/GetOrganelle))
- NOVOplasty ([https://github.com/ndierckx/NOVOPlasty](https://github.com/ndierckx/NOVOPlasty))
- Norgal ([https://bitbucket.org/kosaidtu/norgal/src/master/](https://bitbucket.org/kosaidtu/norgal/src/master/))
- MITObim ([https://github.com/chrishah/MITObim](https://github.com/chrishah/MITObim))

The user may of course choose to use just one, all or any combination of these assemblers. Furthermore, the user may choose to the level to which the raw data are subsampled or instead choose to skip this step and use the entire dataset. The resulting assemblies are then annotated via MITOS ([https://gitlab.com/Bernt/MITOS](https://gitlab.com/Bernt/MITOS)). All assemblies for a given sample-ID are then rolled to a common starting point and reverse complemented if need be. They are then aligned with one another for evaluation of inconsistencies between algorithms using Clustalo v.1.2.4 (Sievers et al., 2011). A second annotation (again using MITOS v.1.0.5) is then run on the rolled assemblies to update the annotation coordinates which are then converted to gbk format using Emboss v.6.6.0’s “seqret” module (https://www.ebi.ac.uk/Tools/sfc/emboss_seqret). CGView Comparison Tool (CCT) v.1.0.1 (https://github.com/paulstothard/cgview_comparison_tool) is used to plot annotated assemblies and compare regions of similarity and difference between different assemblies. Finally, all assemblies, annotation files and maps  are gathered into a html report, generated via R Markdown v.4.0.3 (Baumer & Udwin, 2015). MitoComp uses the pipeline management system Snakemake with all software tools containerized via Docker/Singularity.

## Obtaining and running MitoComp

MitoComp is primarily designed to run on HPC clusters using a TORQUE, SGE or SLURM job scheduling system. It may also be run on a desktop computer using Linux but due to the computationally intensive nature of many of the steps involved, this is not optimal. Other than this MitoComp&#39;s only prerequisites are:

1. A singularity installation (tested with singularity version 3.5.2)
2. A snakemake installation (tested with snakemake 6.0.2; snakemake can be installed through conda using the following commands)

```
conda install -c conda-forge mamba

mamba create -c conda-forge -c bioconda -n snakemake snakemake=6.0.2
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

MitoComp requires two files to run, both of which should be edited by the user prior to running MitoComp. These are the 'data' file and the 'config' file.

The config file (an example is shipped with this repository at data/config.yaml) allows the user to customise the set up of their MitoComp run. First, different combinations of assemblers to be used by adding or removing them from a list. The default config file we provide is set to use all five assemblers:

```
Assembler: ["norgal", "getorganelle", "mitoflex", "novoplasty", "mitobim"]
```
The user may however, only want to use norgal, in which case they would set this to:

```
Assembler: ["norgal"]
```

Or they may wish to use both norgal and MITObim:

```
Assembler: ["norgal", "mitobim"]
```

Etc.

Furthermore, the level of subsampling can be set in a similar manner by editing the sub list.

For example, the following sub list will subsample the datasets thrice: with 5, 10 and 20 million randomly selected reads.

```
sub: ["5000000", "10000000", "20000000"]
```

Users may choose to use all their data instead of subsampling, in which case they may provide the option "all" to this list

```
sub: ["all"]
```

Or they may wish to run their datasets with all data and a subsample of 5 million reads.

```
sub: ["all"]
```


The number of threads given to each rule can be set by the user in the config file. For instance,

```
threads:
   download: 2
   trimming: 24
```

will provide 2 threads for the download rule and 24 threads to the trimming rule.

Some further parameters for the trimming rule are also specified in this file and may be edited by the user

Finally, the config file provides MitoComp with the data file, which corresponds to the user's datasets:

```
samples: "data/data.csv"
```

The data file should be edited to provide information specific to the user&#39;s datasets. This file should be in .csv format and the columns in this file are named as follows:

```
ID,forward,reverse,SRA,seed,Clade,Code,novoplasty_kmer,Read_length,Adapter,Type,GO_Rounds
```

- ID: This column refers to the name of the sample and may be freely completed by the user but we advise against the use of most special characters including &quot;.&quot; and instead advise users to use &quot;_&quot;
- forward, reverse: If the user wishes to provide their own WGS data, the paths to both forward and reverse reads should be provided in the corresponding columns. These reads should be in fastq format and gzipped.
- SRA: MitComp can automatically download read data from NCBI SRA. Enter an SRA accession number here to do so.
- seed: For the assemeblers MITObim, NOVOplasty and GetOrganelle a mitochondrial "seed" sequence from the species in question is required. This seed should be provided by the user and the path to this file should be specified in the seed column. 
- Clade: Mitoflex requires the clade (e.g. Arthropoda, Chordata, Nematoda, Mollusca) of the chosen species which should be entered in the clade column.
- Code: Some of the assemblers and MITOS require the genetic code of the chosen species which should be entered in the clade column. A list of genetic codes may be found here [https://www.ncbi.nlm.nih.gov/Taxonomy/Utils/wprintgc.cgi?mode=c](https://www.ncbi.nlm.nih.gov/Taxonomy/Utils/wprintgc.cgi?mode=c)
- novoplasty_kmer: Novoplasty requires a k-mer length for assembly. Provide an uneven number here.
- Read_length: Length of the provided reads. This is used for trimming.
- Adapter: To perform adapter trimming, a relative path to a file with known adapter sequences should be provided here. These may be downloaded from [https://github.com/usadellab/Trimmomatic/tree/main/adapters]
- Type: For GetOrganelle it is necessary to provide a database type here. Possible values are: 'embplant_pt', 'other_pt', 'embplant_mt', 'embplant_nr', 'animal_mt', 'fungus_mt', 'anonym'. 
- GO_Rounds: This indicates the number of rounds of extension GetOrganelle will complete in order to recruit target-associated reads from the dataset. We recommend using 10 but this figure may need to be raised for lower coverage datasets. 

We also provide users working on a cluster with a template cluster config file for clusters using either a SLURM or a SGE submission system. Resources provided to each job as well as the paths to log files may be set here by the user according to their cluster settings. Please note that the information we provide in these templates should be edited by the user in acordance with the requirements of specific clusters. The cluster config file is called with the "-c" flag.

The following command uses the MitoComp script to run the pipeline on a SLURM system:

```
./MitoComp -t slurm -c data/cluster-config-SLURM.yaml
```

Or on an SGE system:

```
./MitoComp -t sge -c data/cluster-config-SGE.yaml
```

We advise adding the `--dry` option to this command first. This will not submit any jobs but will print jobs to be completed and flag up any errors.

We provide MitoComp three alternate runmodes. These are specified via the -m flag. This determines how far the pipeline should run. For assembly and an initial annotation, specify "-m assembly". To annotate, visualise and compare previously assembled mitochondrial genomes, specify "-m annotate". Restarting the pipeline with this option may be particularly useful in cases where the pipeline fails due to certain assembly jobs reaching wall-time limits. For a complete run, specify "-m all" or ignore this option. For example the following command will run in assembly mode:

```
./MitoComp -m assembly -t slurm -c data/cluster-config-SLURM.yaml
```

Finally, it may occur that one step of the pipeline fails causing subsequent jobs to remain in the queuing system indefinately. This may prevent other jobs from running. The following command will kill all jobs that are depend on this specific instance of MitoComp without affecting other jobs running on the cluster:

```
./MitoComp --reset -t slurm
```

Please note this command also requires the relevant submission system to be set via the "-t" flag.

Finally, for users working with their own raw read data, it is important to ensure Singularity has access to the directory where these files are saved. There are two solutions to this. One may saved the reads within the working directory (i.e. after cloning the repository save the files within the directory MitoComp/). Alternatively, one may set the bind point for singularity in the submission command to a directory upstream of where the files are located. This may be done using the flag "-i" to pass arguments to singularity, then "-B /bind/point/" to set the bind point using an absolute path. An example of this submission command would be:  

```
./MitoComp -t sge -m all -c data/cluster-config-SGE.yaml -i "-B /bind/point/upstream/"
```

