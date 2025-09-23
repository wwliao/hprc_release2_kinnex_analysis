# Kinnex Data Analysis for the HPRC Release 2

This repository provides Nextflow workflows for analyzing PacBio Kinnex long-read RNA sequencing data from 206 individuals in the Human Pangenome Reference Consortium (HPRC) Release 2.

The workflows cover the full pipeline from preprocessing raw reads to downstream QTL mapping, enabling reproducible analysis of expression and regulatory variation.

## Steps

1. Preprocessing

    For each of the 206 HPRC R2 samples, PacBio Kinnex cDNA libraries were sequenced in two runs. Depending on the sequencing facility, the resulting FLNC BAM files were either provided separately (two per sample) or already concatenated into one (see the [index file](https://github.com/human-pangenomics/hprc_intermediate_assembly/blob/main/data_tables/sequencing_data/data_kinnex_pre_release.index.csv) for download links).

    For consistency, we concatenate the two runs into a single FLNC BAM per sample. After concatenation, we update the `SM` field in the `@RG` header line to match the sample ID (instead of default values like `BioSample_1`) and generate the corresponding PBI index.

2. Read Alignment

    To align FLNC reads, each BAM file is converted to FASTQ format. We add the sample ID as a prefix to each read name to ensure uniqueness after pooling across samples. Each FASTQ file is then aligned to the reference genome using minimap2 with GENCODE v48 annotations in BED12 format.

    Finally, the 206 aligned BAM files are merged into a single BAM file for unified transcript model construction across samples.

3. Transcript Discovery
4. Transcript Quantification
5. QTL mapping
