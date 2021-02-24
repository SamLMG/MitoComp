# Assembly_pipeline_feb

Do a dry-run:
```bash
snakemake -np
```

To clone this repository incl. the immediate-submit submodule:

```
git clone --recursive https://github.com/SamLMG/Assembly_pipeline_feb.git
```

Commands to run the pipeline using the assembly script:
```
./assembly -t slurm -c data/cluster-config-VSC3-SLURM.yaml.template
./assembly -t slurm -c data/cluster-config-SLURM.yaml.template
```

