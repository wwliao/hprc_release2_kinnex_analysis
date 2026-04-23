#!/usr/bin/env nextflow

process BAM2FASTQ {
    tag "${sample}"

    input:
    tuple val(sample), path(bam), path(pbi)

    output:
    tuple val(sample), path("${bam.baseName}.fastq.gz")

    script:
    """
    bam2fastq --num-threads ${task.cpus} --seqid-prefix ${sample}_ -o ${bam.baseName} ${bam}
    """
}

process MINIMAP2 {
    tag "${sample}"

    input:
    tuple val(sample), path(fastq)
    path transcript_fasta

    output:
    tuple val(sample), path("${sample}.${transcript_fasta.baseName}.bam")

    script:
    """
    minimap2 -t ${task.cpus} -R "@RG\\tID:${sample}\\tPL:PACBIO\\tDS:READTYPE=SEGMENT;SOURCE=CCS\\tSM:${sample}\\tPM:REVIO" -ax map-hifi --eqx -N 100 ${transcript_fasta} ${fastq} | samtools view -@ ${task.cpus} -b -o ${sample}.${transcript_fasta.baseName}.bam
    """
}

workflow {
    // Read the sample sheet
    Channel
        .fromPath(params.sample_sheet)
        .splitCsv(header: true)
        .map { row -> tuple(row.sample, file(row.flnc_bam), file(row.flnc_pbi)) }
        .set { samples_ch }

    BAM2FASTQ(samples_ch)

    MINIMAP2(BAM2FASTQ.out, file(params.transcript_fasta))
}
