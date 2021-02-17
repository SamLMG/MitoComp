rule norgal:
    input:
        f = rules.subsample.output.f,
        r = rules.subsample.output.r
    output:
#        directory("assemblies/{assembler}/{id}/{sub}/{id}_{assembler}"),
        ok = "assemblies/norgal/{id}/{sub}/norgal.ok"
#    resources:
#        qos="normal_binf -C binf",
#        partition="binf",
#        mem="100G",
#        name="norgal",
#        nnode="-N 1"
    threads: 24
    shell:
        """
        module load intel/18 intel-mkl/2018 python/2.7 numpy/1.12.0 matplotlib/2.2.2
        export PATH="/home/lv71312/leeming/mt_assembly/norgal/binaries/linux:$PATH"        
        python /home/lv71312/leeming/mt_assembly/norgal/norgal.py -i {input.f} {input.r} -o {output} --blast -t {threads}
        touch {output}
        """
