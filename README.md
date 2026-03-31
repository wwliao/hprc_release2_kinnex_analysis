# Kinnex Data Analysis for the HPRC Release 2

This repository provides Nextflow workflows for analyzing PacBio Kinnex long-read RNA sequencing data from 206 individuals in the Human Pangenome Reference Consortium Release 2 (HPRC R2).

The workflows cover the full pipeline from raw read preprocessing to downstream QTL mapping, enabling reproducible analysis of transcript expression and regulatory variation.

## Overview of Workflow

The analysis consists of the following steps:

1. Gene annotation preparation
2. Preprocessing
3. Read alignment
4. Transcript discovery
5. Transcript quantification
6. QTL mapping

## 1. Gene Annotation Preparation

We use [GENCODE Release 48](https://www.gencodegenes.org/human/release_48.html) as the reference gene annotation. The [GTF file](https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_48/gencode.v48.primary_assembly.annotation.gtf.gz) provides comprehensive annotation on the primary assembly.

To ensure consistency with the reference genome, scaffold names are converted from GenBank accession numbers to UCSC-style names using the [assembly report](https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/001/405/GCA_000001405.29_GRCh38.p14/GCA_000001405.29_GRCh38.p14_assembly_report.txt). For example, `KI270706.1` is renamed to `chr1_KI270706v1_random`. The UCSC-style gene annotation file can be downloaded from [here](https://s3-us-west-2.amazonaws.com/human-pangenomics/submissions/5B3D117A-8331-447B-BFDF-1FDB1127A89E--YALE_KINNEX_ANALYSIS_R2/gene_annotations/gencode.v48.primary.ucscstyle.gtf.gz).

## 2. Preprocessing

For each of the 206 HPRC R2 samples, PacBio Kinnex cDNA libraries were sequenced in two runs. Depending on the sequencing facility, the resulting FLNC BAM files were either provided separately (two per sample) or already concatenated into one (see the [index file](https://github.com/human-pangenomics/hprc_intermediate_assembly/blob/main/data_tables/sequencing_data/data_kinnex_pre_release.index.csv) for download links).

For consistency, we concatenate the two runs into a single FLNC BAM per sample. After concatenation, we update the `SM` field in the `@RG` header line to match the sample ID (instead of default values like `BioSample_1`) and generate the corresponding PBI index.

## 3. Read Alignment

To align FLNC reads, each BAM file is converted to FASTQ format. We add the sample ID as a prefix to each read name to ensure uniqueness after pooling across samples. Each FASTQ file is then aligned to the reference genome using minimap2 with [GENCODE v48 annotations in BED12 format](https://s3-us-west-2.amazonaws.com/human-pangenomics/submissions/5B3D117A-8331-447B-BFDF-1FDB1127A89E--YALE_KINNEX_ANALYSIS_R2/gene_annotations/gencode.v48.primary.ucscstyle.bed.gz). An index file, [flnc_alignments.index.csv](https://github.com/wwliao/hprc_release2_kinnex_analysis/blob/main/index_files/flnc_alignments.index.csv), provides download paths for the 206 aligned BAM files. 

Finally, the 206 aligned BAM files are merged into a single BAM file for unified transcript model construction across samples.

## 4. Transcript Discovery

### 4.1 Transcript model construction
    
A unified transcript model across samples is built using the merged BAM file as input to IsoQuant. Because this step is computationally intensive, the merged BAM is split into 25 chromosome-level BAM files. For chromosome 14, only reads within positions 1–104,474,600 are used due to extremely high read depth in the IGH region. This depth arises because the samples are lymphoblastoid cell lines (LCLs), derived from B cells that strongly express IGH genes. The current model construction algorithm cannot handle this region, but all reads on chromosome 14 are still included later during read assignment. IsoQuant is run on each chromosome, and the resulting extended GTFs are combined into a single extended GTF for downstream analysis.
    
### 4.2 Read assignment to transcripts
    
The extended GTF is then used as the unified transcript model. Each per-sample BAM file is processed with IsoQuant to assign reads to known and novel transcripts for qunatification.

### 4.3 Transcript model quality control

## 5. Transcript Quantification
## 6. QTL mapping
