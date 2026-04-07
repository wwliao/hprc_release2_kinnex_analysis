#!/usr/bin/env nextflow

process GFFREAD {
    input:
    path ref_fasta
    path ref_fai
    path transcript_gtf

    output:
    path "${transcript_gtf.baseName}.fa"

    script:
    """
    gffread -w ${transcript_gtf.baseName}.fa -g ${ref_fasta} ${transcript_gtf}
    """
}

workflow {
    GFFREAD(file(params.ref_fasta), file(params.ref_fai), file(params.transcript_gtf))
}
