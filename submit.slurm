#!/bin/bash
#
#SBATCH -J snakemake_master
#SBATCH -N 1
#SBATCH --ntasks-per-node=24
#SBATCH --ntasks-per-core=2
#SBATCH --mem 60G

#SBATCH --qos normal_0064
#SBATCH --partition mem_0064

#SBATCH --output slurm-%j.out
#SBATCH --error slurm-%j.err

#From here on out the magic happens
#first few lines are just some info about the job that will be printed to the log file
echo -e "\n[ $(date) ]\n"
echo "Running under shell '${SHELL}' in directory '$(pwd)' using $SLURM_NTASKS_PER_NODE tasks per node on $SLURM_JOB_NODES nodes ($SLURM_NODEID)"
echo "Host: $HOSTNAME"
echo "Job: $SLURM_JOB_NAME"

module load go/1.11 singularity/3.4.1

snakemake all -s snake_fly --use-conda --use-singularity --singularity-args "-B $BINFL" --cluster "sbatch -J {resources.name} --qos {resources.qos} --partition {resources.partition} {resources.nnode} --ntasks {threads} --mem {resources.mem} --ntasks-per-core=2" --jobs 1000 -p
