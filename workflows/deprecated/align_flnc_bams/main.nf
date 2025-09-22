#!/usr/bin/env nextflow

process PBMM2_ALIGN {
    tag "${sample}"

    input:
    tuple val(sample), path(flnc_bam)
    path ref_mmi

    output:
    tuple val(sample), path("${sample}.${ref_mmi.simpleName}.flnc.bam"), path("${sample}.${ref_mmi.simpleName}.flnc.bam.bai")

    script:
    """
    pbmm2 align --num-threads ${task.cpus} --preset ISOSEQ --sample ${sample} --sort ${ref_mmi} ${flnc_bam} ${sample}.${ref_mmi.simpleName}.flnc.bam
    """
}

workflow {
    // Read the sample sheet
    Channel
        .fromPath(params.sample_sheet)
        .splitCsv(header: true)
        .map { row -> tuple(row.sample, file(row.flnc)) }
        .set { samples_ch }

    PBMM2_ALIGN(samples_ch, file(params.ref_mmi))
}
