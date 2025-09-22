#!/usr/bin/env nextflow

process CLAIR3_RNA {
    tag "${sample}"

    input:
    tuple val(sample), path(bam), path(bai)
    path ref_fasta
    path ref_fai

    output:
    path "${sample}.${ref_fasta.baseName}_no_tagging.vcf.gz"
    path "${sample}.${ref_fasta.baseName}_no_tagging.vcf.gz.tbi"
    path "${sample}.${ref_fasta.baseName}.vcf.gz"
    path "${sample}.${ref_fasta.baseName}.vcf.gz.tbi"


    script:
    """
    /opt/bin/run_clair3_rna --bam_fn ${bam} --ref_fn ${ref_fasta} --output_dir \${PWD} --threads ${task.cpus} --platform hifi_mas_pbmm2 --min_coverage 3 --sample_name ${sample} --output_prefix ${sample}.${ref_fasta.baseName} --remove_intermediate_dir --include_all_ctgs --min_mq 5 --tag_variant_using_readiportal
    """
}

workflow {
    // Read the sample sheet
    Channel
        .fromPath(params.sample_sheet)
        .splitCsv(header: true)
        .map { row -> tuple(row.sample, file(row.bam), file(row.bai)) }
        .set { samples_ch }

    CLAIR3_RNA(samples_ch, file(params.ref_fasta), file(params.ref_fai))
}
