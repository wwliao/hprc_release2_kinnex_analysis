#!/usr/bin/env nextflow

process ISOQUANT {
    tag "${chrom}"

    input:
    tuple val(chrom), path(bam), path(bai), path(ref_fasta), path(ref_fai), path(gencode_gtf)

    output:
    path "HPRC_R2_${chrom}/*"

    script:
    """
    isoquant.py \
        --threads ${task.cpus} \
        --reference ${ref_fasta} \
        --genedb ${gencode_gtf} \
        --complete_genedb \
        --bam ${bam} \
        --read_group tag:RG \
        --data_type pacbio_ccs \
        --fl_data \
        --output HPRC_R2_${chrom} \
        --prefix HPRC_R2_${chrom} \
        --check_canonical \
        --sqanti_output \
        --high_memory
    """
}

workflow {
    // Read the sample sheet
    Channel
        .fromPath(params.sample_sheet)
        .splitCsv(header: true)
        .map { row -> tuple(row.chrom, file(row.bam), file(row.bai), file(row.ref_fasta), file(row.ref_fai), file(row.gencode_gtf)) }
        .set { samples_ch }

    ISOQUANT(samples_ch)
}
