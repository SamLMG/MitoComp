import os
import pandas as pd

IDS = sample_data.index.values.tolist()
def get_accession(wildcards):
	return sample_data.loc[(wildcards.id), ["SRA"]].values[0]

def get_seed(wildcards):
	return sample_data.loc[(wildcards.id), ["seed"]].dropna().values[0]

def get_clade(wildcards):
        return sample_data.loc[(wildcards.id), ["Clade"]].dropna().values[0]

def get_code(wildcards):
        return sample_data.loc[(wildcards.id), ["Code"]].dropna().values[0]

def get_forward(wildcards):
        return sample_data.loc[(wildcards.id), ["forward"]].dropna().values[0]

def get_reverse(wildcards):
        return sample_data.loc[(wildcards.id), ["reverse"]].dropna().values[0]

def get_kmer(wildcards):
	return sample_data.loc[(wildcards.id), ["novoplasty_kmer"]].dropna().values[0]

def get_readlength(wildcards):
        return sample_data.loc[(wildcards.id), ["Read_length"]].dropna().values[0]

def get_adapter(wildcards):
        return sample_data.loc[(wildcards.id), ["Adapter"]].dropna().values[0]

def get_type(wildcards):
        return sample_data.loc[(wildcards.id), ["Type"]].dropna().values[0]

def get_rounds(wildcards):
        return sample_data.loc[(wildcards.id), ["GO_Rounds"]].dropna().values[0]
