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
    path ref_fasta
    path anno_bed

    output:
    tuple val(sample), path("${sample}.${ref_fasta.baseName}.sorted.bam"), path("${sample}.${ref_fasta.baseName}.sorted.bam.bai")

    script:
    """
    minimap2 -t ${task.cpus} -R "@RG\\tID:${sample}\\tPL:PACBIO\\tDS:READTYPE=SEGMENT;SOURCE=CCS\\tSM:${sample}\\tPM:REVIO" -ax splice:hq -uf -Y --MD --junc-bed ${anno_bed} ${ref_fasta} ${fastq} | samtools sort -m 4G -@ ${task.cpus} --write-index -o ${sample}.${ref_fasta.baseName}.sorted.bam##idx##${sample}.${ref_fasta.baseName}.sorted.bam.bai
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

    MINIMAP2(BAM2FASTQ.out, file(params.ref_fasta), file(params.anno_bed))
}
