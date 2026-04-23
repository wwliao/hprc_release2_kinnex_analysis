#!/usr/bin/env nextflow

process OARFISH {
    tag "${sample}"

    input:
    tuple val(sample), path(bam)

    output:
    path "${sample}*"

    script:
    """
    oarfish --threads ${task.cpus} --num-bootstraps 100 --alignments ${bam} --output ${sample} --min-aligned-fraction 0.8 --strand-filter fw --model-coverage --write-assignment-probs
    """
}

workflow {
    // Read the sample sheet
    Channel
        .fromPath(params.sample_sheet)
        .splitCsv(header: true)
        .map { row -> tuple(row.sample, file(row.bam)) }
        .set { samples_ch }

    OARFISH(samples_ch)
}
