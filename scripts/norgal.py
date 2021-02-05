#!/usr/bin/env python

#NORGAL v. 0.1
#Last modified 27 Sep 2017


## loading relevant modules
from __future__ import print_function
from argparse import ArgumentParser
import sys
import os
import subprocess
import shutil
import pickle
import glob

norgalversion = "1.0.0"

## Pointing at the right binaries
## If you want your own version of programs, just overwrite the files in the "binaries" folder with links to your programs.
spath = os.path.dirname(os.path.realpath(sys.argv[0]))
if sys.platform == "darwin":
 bpath = spath+"/binaries/darwin"
# sys.exit("We dont support mac yet...") #IDBA doesnt compile on macs. So as soon as it does, I'll enable this.
else: #Assuming linux..
 bpath = spath+"/binaries/linux"

scripts = spath+"/scripts"
sys.path.append(spath+"/scripts")

## Getting command line arguments
parser = ArgumentParser(prog="norgal",usage="python norgal.py -i reads1.fq reads2.fq -O MyProjectFolder",epilog="Please see github.com/kosaidtu/norgal for more details.",description="Norgal v."+norgalversion+": Mitochondrial genomic DNA extraction from NGS reads.")
parser.add_argument("-i", metavar="FILE",help="Input paired fastq-files. (Required)", nargs=2,required=True)
parser.add_argument("-o", metavar="NAME",help="Folder for output. (Required)",nargs=1,required=True)
parser.add_argument("-r", metavar="FILE",help="Optional nuclear genome assembly of organism. Can be contigs, scaffolds, single nuclear gene etc.",nargs=1)
parser.add_argument("-t", metavar="INTEGER",help="Number of threads. Default=2",type=int,default=2) #Doesn't do anything. Not implemented yet.
parser.add_argument("-c", metavar="INTEGER",help="Depth-cutoff. Default=auto",type=int)
parser.add_argument("-m", metavar="INTEGER",help="Minimum length of scaffold to be considered. Default=10,000bp",type=int,default=10000)
parser.add_argument("-b", metavar="INTEGER",help="Number of contigs to report with BLAST-hits. Default=10",type=int,default=10) # Blast-hits
parser.add_argument("-e", metavar="FLOAT",help="E-value cut-off for BLAST-search. Default=1e-5",type=float,default=0.0001) #1e-5 or 10^-5
parser.add_argument("--trim",help="Remove adapters. Linux-only function. Default=disabled",action="store_true")
#parser.add_argument("--hmm",help="Use COI HMM to get mitochondrial genome instead of longest assembled scaffold. Default=disabled",action="store_true")
parser.add_argument("--blast",help="Use best BLAST-hit from a mitochondrial/plastid database instead of longest assembled scaffold. Default=disabled",action="store_true")
#parser.add_argument("--blast",help="BLAST results against nt database from NCBI. Requires BioPython installed.",action="store_true") # Implement later
parser.add_argument("--delete",help="Remove large temporary files (ie slim-mode)",action="store_true")

args = parser.parse_args()

print(args)

read1 = os.path.realpath(args.i[0])
read2 = os.path.realpath(args.i[1])
o = args.o[0].rstrip("/")

run_genome_assembly = 0
if not args.r:
 #Do genome assembly here
 run_genome_assembly = 1
# sys.exit("NO ARGS")
# pass
else:
 ref = os.path.realpath(args.r[0])


#if sys.platform == "darwin" and args.trim: #AdapterRemoval works with macs now.
# args.trim = False
# print("Trimming uses AdapterRemoval which only works on linux at the time of writing. Skipped trimming.")


#os.chdir(o)

#shutil.rmtree(o) #for debugging. Didnt want to delete the same folder again and again...
try:
 os.chdir(o)
 if os.path.exists("log/checkpoints.p"):
  checkpoint = pickle.load(open("log/checkpoints.p","rb")) #This is the checkpoint list.
  stat = 0
 else:
  sys.exit("**** ERROR! Output-folder already exists. Change -o name please. Exit.")
  #for x in checkpoint:
  # if x == 0:
  #  break
  # stat += 1
except OSError:
 try:
  os.mkdir(o)
  os.chdir(o)
  os.mkdir("log")
  os.mkdir("reads")
  os.mkdir("ref")
  os.mkdir("assemblies")
  os.mkdir("candidates")
  checkpoint = [0 for i in range(22)]
  stat = 0
 except OSError:
  sys.exit("**** ERROR! Output-folder already exists. Change -o name please. Exit.")
 except:
  sys.exit("**** ERROR! Unknown error related to output folder (ie -o option). Exit.")



#Continuing from last checkpoint
errfile=open("log/programs.output","a")
logfile=open("log/status.log","a")
if 1 in checkpoint:
 logfile.write("\n======================\nCONTINUING FROM LAST CHECKPOINT\n======================\n")
 errfile.write("\n======================\nCONTINUING FROM LAST CHECKPOINT\n======================\n")
else:
 errfile.write("The output of the different programs will be in this file.\n")
 errfile.write("----------------------------------------------------------\n\n")
 logfile.write("The status and commands run in the pipeline will be here.\n")
 logfile.write("---------------------------------------------------------\n\n")

def doit2(cmd,message): #Old runner, obsolete
 logfile.write("###### Doing "+message+"....\n")
 logfile.write("COMMAND: "+cmd+"\n\n")
 try:
  hej = subprocess.check_call(cmd,shell=True)
  print("PPPPPPPPPPPPPPPPPPPPPPPP")
  print(hej)
  print("PPPPPPPPPPPPPPPPPPPPPPPP")
  logfile.write("DONE!\n")
 except:
  sys.exit("****** Failed "+message+".. Exit.")

def doit(cmd,message,force=0):
 print(checkpoint)
 print(stat)
 if checkpoint[stat] == 1 and force ==0:
  logfile.write("SKIPPED "+message+"....\n")
 else:
  logfile.write("###### Doing "+message+"....\n")
  logfile.write("COMMAND: "+cmd+"\n\n")
  try:
   hej = subprocess.check_call(cmd,shell=True,stderr=errfile,stdout=errfile)
   print("###########\n"+cmd)
   print("Status (0 is good): {0}".format(hej),end="")
   if force == 0:
    logfile.write("DONE!")
    checkpoint[stat] = 1
    pickle.dump(checkpoint,open("log/checkpoints.p","wb"))
  except Exception as e:
   print(e)
   sys.exit("****** Failed "+message+".. Exit.")


#if sys.platform == "darwin" and args.trim: #AdapterRemoval now works with Darwin. Uncommented this block
# args.trim = False
# logfile.write("*****WARNING!! Trimming uses AdapterRemoval which only works on linux at the time of writing. Skipped trimming.")


def removeit(globs):
 with open("log/deletedfiles.txt","a") as fdel:
  for el in globs:
   try:
    os.remove(el)
    fdel.write("Deleted: {0}\n".format(el))
   except:
    fdel.write("ERROR! Could not delete file: {0}\n".format(el))



# Debugging check point place.
#checkpoint = [0 for i in range(19)]
#checkpoint[0] = 1

#if args.c:
# yes = [1 for i in range(7)]
# no = [0 for i in range(12)]
# checkpoint = yes+no


#### TEST
#checkpoint = [0 for i in range(20)]
#for i in range(11):
# checkpoint[i] = 1


#Adapterremoval
if args.trim:
# if read1[-2:] == "gz":
#  read1 = "<(gzip -cd {0})".format(read1)
# if read2[-2:] == "gz":
#  read2 = "<(gzip -cd {0})".format(read2)
 cmd = "{3}/AdapterRemoval --file1 {0} --file2 {1} --minquality 20 --output1 reads/trim1.fq --output2 reads/trim2.fq --singleton reads/single.fq --discard reads/trim.discarded.fq --settings reads/trim.settings --minlength 30 --trimqualities --basename trim --trimns --threads {2}".format(read1,read2,args.t,bpath)
 doit(cmd,"adapter removal and trimming")
 stat += 1
else:
 gzipcmd = ""
 if read1[-2:] == "gz" or read1[-4:] == "gzip":
  cmd = "{0}/gzip -cd {1} > reads/trim1.fq; {0}/gzip -cd {2} > reads/trim2.fq".format(bpath,read1,read2)
  doit(cmd,"Skipped trimming. Unzipping input files.")
 else:
  cmd = "ln -s {0} reads/trim1.fq; ln -s {1} reads/trim2.fq".format(read1,read2)
  doit(cmd,"Skipped trimming")
 stat += 1
read1 = "reads/trim1.fq"
read2 = "reads/trim2.fq"

#Bwa
### DO GENOME ASSEMBLY HERE! SAVE IT AS ref/genome.fa
if not args.r:
# cmd = "{0}/fq2fa --merge reads/trim1.fq reads/trim2.fq reads/initial_idba.fa".format(bpath)
# doit(cmd,"Converting initial fastq files to fasta",force=1)
#Keep above part for idba_ud assembly. For megahit, delete it.

#Making an initial quick and dirty assembly
# cmd = "{0}/idba_ud -r reads/initial_idba.fa -o assemblies/initial".format(bpath) #OLD_IDBA, new uses megahit
 cmd = "{0}/megahit -1 reads/trim1.fq -2 reads/trim2.fq --k-list 21,49,77,105 -t {1} -o assemblies/initial --mem-flag 0".format(bpath, args.t)
 doit(cmd,"Assembling all reads for ND determination",force=0) #Used to be force=1
## with open("assemblies/initial/scaffold.fa","r") as fid: # OLD_IDBA, NEXT LINE IS MEGAHIT
#with open("assemblies/initial/final.contigs.fa","r") as fid:
#  with open("assemblies/initial/genome.fa","w") as fout:
#   refi = 0
#   line = fid.readline()
#   fout.write(">denovo_ref\n")
#   while line:
#    if line[0] == ">":
#     line = fid.readline().rstrip()
#    else:
#     refi += len(line)
#     fout.write(line)
#     line = fid.readline().rstrip()
#    if refi > 100000:
#     break
# ref = os.path.realpath("assemblies/initial/genome.fa")

###MEGAHIT VERSION
 import sortfasta
 refi = sortfasta.sortfasta("assemblies/initial/final.contigs.fa")
 with open("assemblies/initial/genome.fa","w") as fout:
  fout.write(">denovo_ref\n{0}".format(refi))
 ref = os.path.realpath("assemblies/initial/genome.fa")

stat += 1 #ND Determination assembly

if args.delete:
 removeit(glob.glob("reads/initial_idba.fa")) #removing initial idba reads


#remove ln -s in the next.
cmd = "ln -s {0} ref/genome.fa; {1}/bwa index ref/genome.fa".format(ref,bpath)
doit(cmd,"bwa indexing of assembly")
stat += 1
cmd = "{3}/bwa mem -t {0} -v 1 ref/genome.fa {1} {2} | {3}/samtools view -Sb - > ref/genomeDNA.bam".format(args.t,read1,read2,bpath)
doit(cmd,"bwa mem")
stat += 1

cmd = "{0}/samtools sort ref/genomeDNA.bam ref/genomeDNA.sort".format(bpath)
doit(cmd,"initial_sort")
stat += 1
cmd = "{0}/samtools faidx ref/genomeDNA.sort.bam".format(bpath)
doit(cmd,"initia_faidx")
stat += 1

cmd = "{0}/bedtools genomecov -d -ibam ref/genomeDNA.sort.bam > ref/genome.cov".format(bpath)
doit(cmd,"initial bedtools genomecov")
stat += 1

if args.delete:
 removeit(glob.glob("ref/genome.fa.*")) #removing bwa indeces
 removeit(glob.glob("ref/genomeDNA.*")) #removing bam and bam-related files

cmd = "{0}/make_genomecovplot_single.py ref/genome.cov genome_coverage".format(scripts)
doit(cmd,"Plotting genome coverage depths")
stat += 1

if args.c:
 depth=args.c
else:
 from getdepth import getpercentile
 depth = getpercentile("ref/genome.cov")

#depth = 100
cmd = "{0}/bbnorm.sh in={1} in2={2} passes=1 keepall lowbindepth={3} highbindepth={4} outhigh=reads/mtreads.fq -Xmx16g".format(scripts,read1,read2,depth-1,depth)
doit(cmd,"bbnorm (kmer binning)")
stat += 1

cmd = "{0}/fq2fa --paired reads/mtreads.fq reads/idba.fa".format(bpath)
doit(cmd,"Converting fastq files to fasta")
stat += 1

#UNCOMMENT NEXT BLOCK FOR REAL VERSION
if sys.platform == "darwin":
 cmd = "{0}/megahit --12 reads/mtreads.fq --min-count 3 --k-min 21 --k-max 101 --k-step 20 --no-mercy -t 2 --mem-flag 0 -o assemblies/mtdna".format(bpath)
 doit(cmd,"Assembling mtDNA reads")
 shutil.move("assemblies/mtdna/final.contigs.fa","assemblies/mtdna/scaffold.fa")
else:
 cmd = "{0}/idba_ud --pre_correction -r reads/idba.fa -o assemblies/mtdna".format(bpath)
 doit(cmd,"Assembling mtDNA reads")

#CHANGE NEXT 3 LINES, FOR MEGAHIT TESTING ONLY.....
#cmd = "{0}/megahit --12 reads/mtreads.fq --min-count 3 --k-min 21 --k-max 101 --k-step 20 --no-mercy -t 2 --mem-flag 0 -o assemblies/mtdna".format(bpath)
#doit(cmd,"Assembling mtDNA reads")
#shutil.move("assemblies/mtdna/final.contigs.fa","assemblies/mtdna/scaffold.fa")
stat += 1


if args.delete:
# removeit(glob.glob("reads/mtreads.fq")) #removing reads from pre-assembly binning
 removeit(glob.glob("reads/idba.fa")) #removing reads used for assembly
 if sys.platform != "darwin":
  removeit(glob.glob("assemblies/*/*0*")) #Removing assembly temp-files
  removeit(glob.glob("assemblies/*/kmer"))
  removeit(glob.glob("assemblies/*/begin"))
  removeit(glob.glob("assemblies/*/end"))


# HMM PART
import getcandidates
import getblasthits
#cmd = "{0}/nhmmscan --tblout ref/coihmm.tab -o ref/coihmm.out -T 100 {1}/hmm/coi_clustal.hmm assemblies/mtdna/scaffold.fa".format(bpath,scripts)
cmd = "{0}/blastn -evalue {2} -outfmt 6 -query assemblies/mtdna/scaffold.fa -db {1}/blast/mpblast.fna -out ref/blast.m8".format(bpath,scripts,args.e)
doit(cmd,"Annotating candidates with reference mito/plastid sequences with BLAST")
stat += 1
longest = 1

Lcoil2,Lsort,printcoi = getblasthits.main("ref/blast.m8",scripts,args.b,args.blast)
if args.blast:
 longest = 0

 if len(Lcoil2) == 0: #Strange Mitochondria/chloroplast with no known homologue
  longest = 1
 else:
  shutil.copyfile("candidates/{0}.fna".format( Lsort[0][1].split(":")[0]  ), "candidate.fna"  )
  checkpoint[stat] = 1 #Hopefully skips next step..
  cmd = "{0}/getfirstfasta.py assemblies/mtdna/scaffold.fa longest.fa".format(scripts)
  doit(cmd,"getting first fasta")
  stat += 1
  cmd = "{0}/circularize.py {1}".format(scripts,Lcoil2)
  doit(cmd,"Circularizing")
  stat += 1
  cmd = "mv circular.fa circular.candidate.fa; cd ref; ln -s ../circular.candidate.fa circular.fa; cd ..; {0}/bwa index ref/circular.fa".format(bpath,Lcoil2)
  doit(cmd,"Indexing circular")
  stat += 1
if longest == 1:
 #Make get first fasta behave differently
# cmd = "{0}/getfirstfasta.py assemblies/mtdna/scaffold.fa candidates/longest.fna".format(scripts)
 cmd = "{0}/getfirstfasta_megahit.py assemblies/mtdna/scaffold.fa candidates/longest.fna".format(scripts)
 doit(cmd,"getting first fasta")
 stat += 1
 cmd = "{0}/circularize.py candidates/longest.fna".format(scripts)
 doit(cmd,"Circularizing")
 stat += 1
 cmd = "mv circular.fa circular.longest.fa; cd ref; ln -s ../circular.longest.fa circular.fa; cd ..; {0}/bwa index ref/circular.fa".format(bpath)
 doit(cmd,"Indexing circular")
 stat += 1

if checkpoint[stat] != 1:
 logfile.write("Separating interleaved fastq-file...")
 with open("reads/mtreads.fq") as fid:
  with open("reads/mtread1.fq","w") as f1:
   with open("reads/mtread2.fq","w") as f2:
    line = fid.readline()
    while line:
     sup = f1.write(line)
     for i in range(3):
      sup = f1.write(fid.readline())
     for i in range(4):
      sup = f2.write(fid.readline())
     line = fid.readline()
    else:
     logfile.write("Done!\n")
checkpoint[stat] = 1
stat += 1


cmd = "{0}/bwa mem -t {1} -v 1 ref/circular.fa reads/mtread1.fq reads/mtread2.fq | {0}/samtools view -Sb - > ref/circular.bam".format(bpath,args.t)
doit(cmd,"Mapping reads to potential mtdna")
stat += 1

cmd = "{0}/samtools sort ref/circular.bam ref/circular.sort".format(bpath)
doit(cmd,"sorting final mtdna")
stat += 1
cmd = "{0}/samtools faidx ref/circular.sort.bam".format(bpath)
doit(cmd,"indexing final bam")
stat += 1

cmd = "{0}/bedtools genomecov -d -ibam ref/circular.sort.bam > ref/circular.cov".format(bpath)
doit(cmd,"mtDNA bedtools genomecov")
stat += 1

cmd = "cat candidates/*fna > candidates/all.fna; {0}/arwen -w -o ref/tRNA.annotations candidates/all.fna;".format(bpath)
doit(cmd,"Annotating tRNA")
removeit(glob.glob("candidates/all.fa"))

#L.append( [ Type,contigL,perc,alen,slen,Eval,score,name  ]  )
#with open("ref/tRNA.annotations") as fid:
# tiD = {}
# line = fid.readline()
# while line:
#  if line[0:2] == ">s":
#   tiScaffold = line[1:].split("_length")[0]
#   tiD[tiScaffold] = fid.readline().split()[0]
#   #Lsort.insert(ti,no_of_genes)
#  line = fid.readline()

#for ti in range(0,args.b):
# Lsort.insert(ti,tiD[  Lsort[ti][1].split(":")[0] ]  )    
 
#with open("blast.report","w") as fout:
# fout.write(printcoi)
# for i in Lsort[0:b]:
#  fout.write("{0}\n".format("\t".join(   [str(x) for x  in i]  )    )  )


stat += 1

cmd = "{0}/make_genomecovplot_pair.py ref/circular.cov ref/genome.cov {1} mtDNA_coverage_plot".format(scripts,depth)
doit(cmd,"Plotting mtDNA coverage depths")


#cmd = "{0}/make_genomecovplot.py ref/circular.cov mtDNA_coverage.png".format(scripts)
#doit(cmd,"Plotting mtDNA coverage depths")

if args.delete:
# removeit(glob.glob("reads/initial_idba.fa")) #removing initial idba reads
# removeit(glob.glob("ref/genome.fa.*")) #removing bwa indeces
# removeit(glob.glob("ref/genomeDNA.*")) #removing bam and bam-related files
# removeit(glob.glob("reads/mtreads.fq")) #removing reads from pre-assembly binning
# removeit(glob.glob("reads/idba.fa")) #removing reads used for assembly
# removeit(glob.glob("assemblies/*/*0*")) #Removing assembly temp-files
# removeit(glob.glob("assemblies/*/kmer")) 
# removeit(glob.glob("assemblies/*/begin")) 
# removeit(glob.glob("assemblies/*/end"))
 removeit(glob.glob("ref/circular.fa.*")) #removing bwa indeces for candidate
 removeit(glob.glob("reads/mtread*")) #removing fasta for post-assembly mapping
 removeit(glob.glob("ref/circular*bam")) #removing bam files for assembly

#if args.hmm:
# errfile.write(printcoi)

errfile.close()
logfile.close()
print("########## PROGRAM FINISHED ##########")






