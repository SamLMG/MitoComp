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

