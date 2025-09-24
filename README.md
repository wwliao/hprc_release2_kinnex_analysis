# Kinnex Data Analysis for the HPRC Release 2

This repository provides Nextflow workflows for analyzing PacBio Kinnex long-read RNA sequencing data from 206 individuals in the Human Pangenome Reference Consortium (HPRC) Release 2.

The workflows cover the full pipeline from preprocessing raw reads to downstream QTL mapping, enabling reproducible analysis of expression and regulatory variation.

## Steps

0. Gene Annotation Preparation

    We use [GENCODE Release 48](https://www.gencodegenes.org/human/release_48.html) as the reference gene annotation. The [GTF file](https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_48/gencode.v48.primary_assembly.annotation.gtf.gz) provides comprehensive annotation on the primary assembly.

    To ensure consistency with the reference genome, scaffold names are converted from GenBank accession numbers to UCSC-style names using the [assembly report](https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/001/405/GCA_000001405.29_GRCh38.p14/GCA_000001405.29_GRCh38.p14_assembly_report.txt). For example, `KI270706.1` is renamed to `chr1_KI270706v1_random`.

1. Preprocessing

    For each of the 206 HPRC R2 samples, PacBio Kinnex cDNA libraries were sequenced in two runs. Depending on the sequencing facility, the resulting FLNC BAM files were either provided separately (two per sample) or already concatenated into one (see the [index file](https://github.com/human-pangenomics/hprc_intermediate_assembly/blob/main/data_tables/sequencing_data/data_kinnex_pre_release.index.csv) for download links).

    For consistency, we concatenate the two runs into a single FLNC BAM per sample. After concatenation, we update the `SM` field in the `@RG` header line to match the sample ID (instead of default values like `BioSample_1`) and generate the corresponding PBI index.

2. Read Alignment

    To align FLNC reads, each BAM file is converted to FASTQ format. We add the sample ID as a prefix to each read name to ensure uniqueness after pooling across samples. Each FASTQ file is then aligned to the reference genome using minimap2 with GENCODE v48 annotations in BED12 format.

    Finally, the 206 aligned BAM files are merged into a single BAM file for unified transcript model construction across samples.

3. Transcript Discovery

    - Transcript model construction
    
        A unified transcript model across samples is built using the merged BAM file as input to IsoQuant. Because this step is computationally intensive, the merged BAM is split into 25 chromosome-level BAM files. IsoQuant is run on each chromosome, and the resulting extended GTFs are combined into a single extended GTF for downstream analysis.
    
    - Read assignment to transcripts
    
        The extended GTF is then used as the unified transcript model. Each per-sample BAM file is processed with IsoQuant to assign reads to known and novel transcripts for qunatification.

4. Transcript Quantification
5. QTL mapping
