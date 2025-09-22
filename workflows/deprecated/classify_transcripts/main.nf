#!/usr/bin/env nextflow

process PIGEON_PREPARE {
    tag "${sample}"

    input:
    tuple val(sample), path(collapsed_gff)

    output:
    tuple val(sample), path("${collapsed_gff.baseName}.sorted.gff"), path("${collapsed_gff.baseName}.sorted.gff.pgi")

    script:
    """
    pigeon prepare ${collapsed_gff}
    """
}

process PIGEON_CLASSIFY {
    tag "${sample}"

    input:
    tuple val(sample), path(collapsed_sorted_gff), path(collapsed_flnc_count)
    path anno_gtf
    path anno_pgi
    path ref_fasta
    path ref_fai
    path cage_bed
    path cage_pgi
    path polya
    path junction_tsv
    path junction_pgi

    output:
    tuple val(sample), path("${sample}_classification.txt"), path("${sample}_junctions.txt"), emit: classification
    path "${sample}.report.json"
    path "${sample}.summary.txt"

    script:
    """
    pigeon classify --num-threads ${task.cpus} --flnc ${collapsed_flnc_count} --cage-peak ${cage_bed} --poly-a ${polya} --coverage ${junction_tsv} --out-prefix ${sample} ${collapsed_sorted_gff} ${anno_gtf} ${ref_fasta}
    """
}

process PIGEON_FILTER {
    tag "${sample}"

    input:
    tuple val(sample), path(collapsed_sorted_gff), path(classification), path(junctions)

    output:
    tuple val(sample), path("${sample}_classification.filtered_lite_classification.txt"), emit: filtered_classification
    path "${sample}_classification.filtered_lite_junctions.txt"
    path "${sample}_classification.filtered_lite_reasons.txt"
    path "${sample}_classification.filtered.report.json"
    path "${sample}_classification.filtered.summary.txt"
    path "${sample}.collapsed.sorted.filtered_lite.gff"

    script:
    """
    pigeon filter --num-threads ${task.cpus} --isoforms ${collapsed_sorted_gff} ${classification}
    """
}

process PIGEON_REPORT {
    tag "${sample}"

    input:
    tuple val(sample), path(classification)

    output:
    tuple val(sample), path("${sample}.saturation.txt")

    script:
    """
    pigeon report --num-threads ${task.cpus} --exclude-singletons ${classification} ${sample}.saturation.txt
    """
}

workflow {
    // Read the sample sheet
    Channel
        .fromPath(params.sample_sheet)
        .splitCsv(header: true)
        .map { row -> tuple(row.sample, file(row.collapsed_gff), file(row.collapsed_flnc_count)) }
        .set { samples_ch }

    PIGEON_PREPARE(samples_ch.map { sample, collapsed_gff, collapsed_flnc_count -> tuple(sample, collapsed_gff) })

    // Combine samples_ch with PIGEON_PREPARE output
    classify_input = samples_ch
        .join(PIGEON_PREPARE.out)
        .map { sample, collapsed_gff, collapsed_flnc_count, collapsed_sorted_gff, collapsed_sorted_pgi -> tuple(sample, collapsed_sorted_gff, collapsed_flnc_count) }

    PIGEON_CLASSIFY(classify_input, file(params.anno_gtf), file(params.anno_pgi), file(params.ref_fasta), file(params.ref_fai), file(params.cage_bed), file(params.cage_pgi), file(params.polya), file(params.junction_tsv), file(params.junction_pgi))

    filter_input = PIGEON_PREPARE.out
        .join(PIGEON_CLASSIFY.out.classification)
        .map { sample, collapsed_sorted_gff, collapsed_sorted_pgi, classification, junctions -> tuple(sample, collapsed_sorted_gff, classification, junctions) }

    PIGEON_FILTER(filter_input)

    PIGEON_REPORT(PIGEON_FILTER.out.filtered_classification)
}
