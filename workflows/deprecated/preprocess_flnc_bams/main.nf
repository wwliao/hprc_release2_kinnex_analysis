#!/usr/bin/env nextflow

process SAMTOOLS_CAT {
    tag "${sample}"

    input:
    tuple val(sample), path(bams)

    output:
    tuple val(sample), path("${sample}.merged.flnc.bam")

    script:
    def additional_bams = bams[1..-1].collect{ "$it" }.join(' ')
    """
    samtools view --no-PG -H ${bams[0]} > header.txt

    additional_rg=\$(for bam in "${additional_bams}"; do
        samtools view -H "\$bam" | grep '^@RG'
    done | sort -u)

    awk -v rg_lines="\$additional_rg" '
    /^@RG/ { if (!seen++) { print; print rg_lines; next } }
    { print }
    ' header.txt > merged_header.txt

    samtools cat --no-PG -h merged_header.txt -o ${sample}.merged.flnc.bam ${bams}
    """
}

process SAMTOOLS_REHEADER {
    tag "${sample}"

    input:
    tuple val(sample), path(bam)

    output:
    tuple val(sample), path("${sample}.flnc.bam")

    script:
    """
    samtools reheader --no-PG -c "sed -E '/^@RG/ s/(SM:)[^[:space:]]+/\\1'${sample}'/'" ${bam} > ${sample}.flnc.bam
    """
}

process PBINDEX {
    tag "${sample}"

    input:
    tuple val(sample), path(bam)

    output:
    tuple val(sample), path(bam), path("${bam}.pbi")

    script:
    """
    pbindex --num-threads ${task.cpus} ${bam}
    """
}

workflow {
    // Read the sample sheet
    Channel
        .fromPath(params.sample_sheet)
        .splitCsv(header: true)
        .map { row -> tuple(row.sample, file(row.flnc)) }
        .groupTuple(by: 0)
        .map { sample, flnc_files -> 
            tuple(sample, flnc_files.sort { it.name })
        }
        .branch {
            multiple: it[1].size() > 1
            single: it[1].size() == 1
        }
        .set { samples_ch }

    SAMTOOLS_CAT(samples_ch.multiple)

    all_samples_ch = SAMTOOLS_CAT.out.mix(samples_ch.single)

    SAMTOOLS_REHEADER(all_samples_ch)

    PBINDEX(SAMTOOLS_REHEADER.out)
}
