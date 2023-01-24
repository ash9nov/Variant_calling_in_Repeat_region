# Variant_calling_in_Repeat_region

1. First use GATK to get the base counts for each position in the capture regions \
    ` gatk DepthOfCoverage -R ${reference.fasta} -I ${bam_file} -O ${sample_name}.DepthOfCoverage.txt -L calling_region.interval_list --print-base-counts true `

2. Calling the variant by msh2.bash (attached), and add the variant at the end of the normal variant calling result file, finally sort the vcf file by the genomic position 
 
   ` /bin/bash msh2.bash ${sample_name}.DepthOfCoverage.txt ${analysis_name}.vcf `
   ` picard SortVcf I=${analysis_name}.vcf O=${analysis_name}.final.vcf `

The msh2.bash is only working to find the variant located at 2:47641560. If the reference base ratio is between 0.25 and 0.75, the script will predict the variant as 0/1. 

