rule report:
    input:
        pick_mode
    output:
        "output/report/report.html"
    params:
        wd = os.getcwd()
    singularity:
        "docker://reslp/rmarkdown:4.0.3"
    shell:
        """     
        # gather bedfiles
        # bedfiles all have the same name, therfore this hack to find, rename and copy the files to a location in the report directory.
        mkdir -p output/report/bedfiles
        for bedfile in $(find ./output/*/annotation/second_mitos/*/ -name "result.bed"); do
            name=$(echo $bedfile | awk -F/ '{{print $6}}')
            cp $bedfile output/report/bedfiles/$name.bed
        done
        
        # gather assemblies
        assemblies=$(find ./output/*/annotation/alignment/*.final.fasta)
        mkdir -p output/report/assemblies
        cp $assemblies output/report/assemblies 2>/dev/null || :
        while read first rest
            file=$first
            position=$rest
            prefix1=$(echo $first | cut -d "/" -f3 | cut -d "." -f 1)
            prefix2=$(echo $first | cut -d "/" -f3 | cut -d "." -f 1-3)
        do
        echo $prefix2
        if [ ! -z "$prefix2" ]
        then
            sed -i "s#>.*#>$prefix2#g" output/report/assemblies/$prefix2.final.fasta
        else
            echo $prefix2
            break 
        fi
        done < output/stats/start_positions.txt
        
        # gather maps   
        maps=$(find ./output/*/annotation/compare/CCT/*.png)
        mkdir -p output/report/maps
        cp $maps output/report/maps 2>/dev/null || :
                
        # copy genes file
        cp output/stats/Genes.txt output/report/Genes.txt
                        
        # create report
        Rscript -e 'rmarkdown::render("./scripts/report.Rmd")'
        
        # clean up
        mv scripts/report.html output/report/report.html
        tar -pcf {params.wd}/output/report.tar -C {params.wd}/output/ report
        """     
