#!/usr/bin/env nextflow

process ISOQUANT {
    tag "${sample}"

    input:
    tuple val(sample), path(bam), path(bai)
    path(ref_fasta)
    path(ref_fai)
    path(extended_gtf)

    output:
    path "HPRC_R2_FLNC_${sample}/*"

    script:
    """
    isoquant.py \
        --threads ${task.cpus} \
        --reference ${ref_fasta} \
        --genedb ${extended_gtf} \
        --complete_genedb \
        --bam ${bam} \
        --read_group tag:RG \
        --data_type pacbio_ccs \
        --fl_data \
        --output HPRC_R2_FLNC_${sample} \
        --prefix HPRC_R2_FLNC_${sample} \
        --check_canonical \
        --sqanti_output \
        --high_memory \
        --no_model_construction
    """
}

workflow {
    // Read the sample sheet
    Channel
        .fromPath(params.sample_sheet)
        .splitCsv(header: true)
        .map { row -> tuple(row.sample, file(row.bam), file(row.bai)) }
        .set { samples_ch }

    ISOQUANT(samples_ch, file(params.ref_fasta), file(params.ref_fai), file(params.extended_gtf))
}
