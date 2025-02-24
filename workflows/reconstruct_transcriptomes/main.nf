#!/usr/bin/env nextflow

process ISOSEQ_CLUSTER2 {
    tag "${sample}"

    input:
    tuple val(sample), path(flnc_bam)

    output:
    tuple val(sample), path("${sample}.clustered.bam"), emit: clustered_bam
    path "${sample}.clustered.bam.pbi"
    path "${sample}.clustered.cluster_report.csv"

    script:
    """
    isoseq cluster2 --num-threads ${task.cpus} ${flnc_bam} ${sample}.clustered.bam
    """
}

process PBMM2_ALIGN {
    tag "${sample}"

    input:
    tuple val(sample), path(clustered_bam)
    path ref_mmi

    output:
    tuple val(sample), path("${sample}.${ref_mmi.simpleName}.aligned.bam"), emit: aligned_bam
    path "${sample}.${ref_mmi.simpleName}.aligned.bam.bai"

    script:
    """
    pbmm2 align --num-threads ${task.cpus} --preset ISOSEQ --sample ${sample} --sort ${ref_mmi} ${clustered_bam} ${sample}.${ref_mmi.simpleName}.aligned.bam
    """
}

process ISOSEQ_COLLAPSE {
    tag "${sample}"

    input:
    tuple val(sample), path(flnc_bam), path(flnc_pbi), path(aligned_bam)

    output:
    path "${sample}.collapsed.abundance.txt"
    path "${sample}.collapsed.fasta"
    path "${sample}.collapsed.flnc_count.txt"
    path "${sample}.collapsed.gff"
    path "${sample}.collapsed.group.txt"
    path "${sample}.collapsed.read_stat.txt"
    path "${sample}.collapsed.report.json"

    script:
    """
    isoseq collapse --num-threads ${task.cpus} --do-not-collapse-extra-5exons ${aligned_bam} ${flnc_bam} ${sample}.collapsed.gff
    """

}

workflow {
    // Read the sample sheet
    Channel
        .fromPath(params.sample_sheet)
        .splitCsv(header: true)
        .map { row -> tuple(row.sample, file(row.flnc), file(row.pbi)) }
        .set { samples_ch }

    ISOSEQ_CLUSTER2(samples_ch.map { sample, flnc, pbi -> tuple(sample, flnc) })

    PBMM2_ALIGN(ISOSEQ_CLUSTER2.out.clustered_bam, file(params.ref_mmi))

    // Combine samples_ch with PBMM2_ALIGN output
    collapse_input = samples_ch
        .join(PBMM2_ALIGN.out.aligned_bam)
        .map { sample, flnc, pbi, aligned_bam -> tuple(sample, flnc, pbi, aligned_bam) }

    ISOSEQ_COLLAPSE(collapse_input)
}
