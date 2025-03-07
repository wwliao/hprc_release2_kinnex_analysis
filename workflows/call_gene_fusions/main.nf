#!/usr/bin/env nextflow

process PBFUSION_DISCOVER {
    tag "${sample}"

    input:
    tuple val(sample), path(bam)
    path gtf

    output:
    path "${bam.baseName}.breakpoints.groups.bed"
    path "${bam.baseName}.breakpoints.bed"
    path "${bam.baseName}.transcripts"
    path "${bam.baseName}.unannotated.bed"
    path "${bam.baseName}.unannotated.clusters.bed"

    script:
    """
    pbfusion discover --verbose --gtf ${gtf} --output-prefix ${bam.baseName} --threads ${task.cpus} ${bam}
    """
}

workflow {
    // Read the sample sheet
    Channel
        .fromPath(params.sample_sheet)
        .splitCsv(header: true)
        .map { row -> tuple(row.sample, file(row.bam)) }
        .set { samples_ch }

    PBFUSION_DISCOVER(samples_ch, file(params.gtf))
}
