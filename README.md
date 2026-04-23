# Kinnex Data Analysis for the HPRC Release 2

This repository provides Nextflow workflows for analyzing PacBio Kinnex long-read RNA sequencing data from 206 individuals in the Human Pangenome Reference Consortium Release 2 (HPRC R2). The workflows cover the full pipeline from raw read preprocessing to downstream QTL mapping, enabling reproducible analysis of transcript expression and regulatory variation.

## Workflow Overview

The analysis consists of gene annotation preparation, preprocessing of raw reads, read alignment, transcript discovery, transcript quantification, and QTL mapping.

## 1. Gene Annotation Preparation

We use [GENCODE Release 48](https://www.gencodegenes.org/human/release_48.html) as the reference gene annotation. The corresponding [GTF file](https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_48/gencode.v48.primary_assembly.annotation.gtf.gz) provides comprehensive annotation on the primary assembly.

To ensure consistency with the reference genome, scaffold names are converted from GenBank accession numbers to UCSC-style names using the [assembly report](https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/001/405/GCA_000001405.29_GRCh38.p14/GCA_000001405.29_GRCh38.p14_assembly_report.txt). For example, `KI270706.1` is renamed to `chr1_KI270706v1_random`. The converted annotation file is available as [gencode.v48.primary.ucscstyle.gtf.gz](https://s3-us-west-2.amazonaws.com/human-pangenomics/submissions/5B3D117A-8331-447B-BFDF-1FDB1127A89E--YALE_KINNEX_ANALYSIS_R2/gene_annotations/gencode.v48.primary.ucscstyle.gtf.gz).

## 2. Preprocessing

For each of the 206 HPRC R2 samples, PacBio Kinnex cDNA libraries were sequenced in two runs. Depending on the sequencing facility, FLNC BAM files are either provided separately (two per sample) or already concatenated (see the [data index file](https://github.com/human-pangenomics/hprc_intermediate_assembly/blob/main/data_tables/sequencing_data/data_kinnex_pre_release.index.csv)).

To standardize inputs across samples, we concatenate the two runs into a single FLNC BAM per sample when needed. After concatenation, the `SM` field in the `@RG` header is updated to match the sample ID (instead of default values like `BioSample_1`), and a corresponding PBI index is generated.

## 3. Read Alignment

FLNC BAM files are converted to FASTQ format prior to alignment. To avoid read name collisions when aggregating data across samples, the sample ID is added as a prefix to each read name.

Reads are aligned to the reference genome using minimap2 with GENCODE v48 gene annotations converted to BED12 format ([gencode.v48.primary.ucscstyle.bed.gz](https://s3-us-west-2.amazonaws.com/human-pangenomics/submissions/5B3D117A-8331-447B-BFDF-1FDB1127A89E--YALE_KINNEX_ANALYSIS_R2/gene_annotations/gencode.v48.primary.ucscstyle.bed.gz)). The resulting aligned BAM files for all samples are available via the index file [flnc_alignments.index.csv](https://github.com/wwliao/hprc_release2_kinnex_analysis/blob/main/index_files/flnc_alignments.index.csv), which provides the corresponding S3 paths. Files can be downloaded using the [AWS CLI](https://aws.amazon.com/cli/): `aws s3 --no-sign-request cp <s3_path> .`.

For unified transcript model construction, all per-sample BAM files are merged into a single BAM file to enable joint analysis across samples.

## 4. Transcript Discovery

### 4.1 Transcript model construction
    
A unified transcript model is constructed across all samples using IsoQuant. To improve computational efficiency, the merged BAM is split into chromosome-level BAM files and processed independently.

For chromosome 14, only reads within positions 1–104,474,600 are used during model construction due to extremely high read depth in the IGH region. This depth arises because the samples are lymphoblastoid cell lines (LCLs), derived from B cells with strong IGH expression. The current model construction algorithm cannot efficiently handle this region. Importantly, all reads from chromosome 14 are retained in downstream steps, including read assignment and quantification.

IsoQuant is applied to each chromosome, and the resulting extended GTF files are concatenated into a single extended GTF.

### 4.2 Read assignment to transcripts
    
The extended GTF serves as the unified transcript model. Each per-sample BAM file is processed with IsoQuant to assign reads to both known and novel transcripts, producing per-sample transcript-level assignments.

### 4.3 Transcript model quality control

To ensure the reliability of the unified transcript model, quality control is performed using SQANTI3. This step evaluates structural and annotation consistency of both known and novel transcripts, and provides classification and quality metrics based on splice junction support, transcript completeness, and agreement with reference annotation.

To improve robustness, multiple orthogonal sources of evidence are incorporated during QC, including splice junction support from short-read data, CAGE peaks for transcription start sites, polyA signals and peaks for transcript termination, and evolutionary conservation scores. These features provide complementary validation of transcript structures beyond the input long-read data.

Based on these metrics, low-confidence transcripts (e.g., those with insufficient support or likely artifacts) are filtered out. At the same time, transcripts with strong supporting evidence are retained through a rescue step, even if they do not fully match reference annotations. This procedure balances sensitivity and specificity, removing likely artifacts while preserving biologically meaningful novel transcripts.

The unified transcript model after quality control is available for download as [HPRC_R2_FLNC.final_extended_annotation.gtf.gz](https://s3-us-west-2.amazonaws.com/human-pangenomics/submissions/5B3D117A-8331-447B-BFDF-1FDB1127A89E--YALE_KINNEX_ANALYSIS_R2/gene_annotations/HPRC_R2_FLNC.final_extended_annotation.gtf.gz).

## 5. Transcript Quantification

### 5.1 Transcript sequence extraction

Transcript sequences are extracted from the quality-controlled unified transcript annotation, [HPRC_R2_FLNC.final_extended_annotation.gtf.gz](https://s3-us-west-2.amazonaws.com/human-pangenomics/submissions/5B3D117A-8331-447B-BFDF-1FDB1127A89E--YALE_KINNEX_ANALYSIS_R2/gene_annotations/HPRC_R2_FLNC.final_extended_annotation.gtf.gz), using gffread together with the reference genome sequence. This step generates the corresponding transcript FASTA file, [HPRC_R2_FLNC.final_extended_annotation.fa.gz](https://s3-us-west-2.amazonaws.com/human-pangenomics/submissions/5B3D117A-8331-447B-BFDF-1FDB1127A89E--YALE_KINNEX_ANALYSIS_R2/gene_annotations/HPRC_R2_FLNC.final_extended_annotation.fa.gz), which is used for downstream transcript-level quantification.

### 5.2 Read alignment to transcript sequences

Preprocessed FLNC BAM files (see [Step 2: Preprocessing](#2-preprocessing)) are converted to FASTQ format. Reads are then aligned to the transcript sequences using minimap2 with `-ax map-hifi --eqx -N 100`, and the resulting alignments are stored in BAM format.

### 5.3 Transcript abundance estimation

Alignments of FLNC reads to transcript sequences are used as input for estimating transcript abundance using [oarfish](https://github.com/COMBINE-lab/oarfish) with `--min-aligned-fraction 0.8 --strand-filter fw --model-coverage`.

Oarfish estimates transcript abundance using a probabilistic model that accounts for alignment quality, read placement along transcripts, and coverage patterns. Transcript abundances are inferred using an expectation–maximization EM algorithm. By modeling coverage consistency along transcripts, this approach improves the resolution of ambiguous read assignments.

The resulting values are floating-point rather than integers, as reads may be probabilistically assigned across multiple transcripts when they are compatible with more than one isoform. This reflects uncertainty in read assignment.

These outputs are aggregated across samples to generate transcript-level and gene-level expression matrices using a custom R script for downstream analyses such as QTL mapping.

The resulting expression matrices are available for download:

- Transcript-level (floating-point): [HPRC_R2_FLNC.transcript_level_counts.float.tsv.gz](https://s3-us-west-2.amazonaws.com/human-pangenomics/submissions/5B3D117A-8331-447B-BFDF-1FDB1127A89E--YALE_KINNEX_ANALYSIS_R2/estimated_counts/HPRC_R2_FLNC.transcript_level_counts.float.tsv.gz)
- Transcript-level (integer, rounded): [HPRC_R2_FLNC.transcript_level_counts.tsv.gz](https://s3-us-west-2.amazonaws.com/human-pangenomics/submissions/5B3D117A-8331-447B-BFDF-1FDB1127A89E--YALE_KINNEX_ANALYSIS_R2/estimated_counts/HPRC_R2_FLNC.transcript_level_counts.tsv.gz)
- Gene-level (floating-point): [HPRC_R2_FLNC.gene_level_counts.float.tsv.gz](https://s3-us-west-2.amazonaws.com/human-pangenomics/submissions/5B3D117A-8331-447B-BFDF-1FDB1127A89E--YALE_KINNEX_ANALYSIS_R2/estimated_counts/HPRC_R2_FLNC.gene_level_counts.float.tsv.gz)
- Gene-level (integer, rounded): [HPRC_R2_FLNC.gene_level_counts.tsv.gz](https://s3-us-west-2.amazonaws.com/human-pangenomics/submissions/5B3D117A-8331-447B-BFDF-1FDB1127A89E--YALE_KINNEX_ANALYSIS_R2/estimated_counts/HPRC_R2_FLNC.gene_level_counts.tsv.gz)

The floating-point values are the original outputs from oarfish. Integer versions are generated for compatibility with downstream tools that require integer counts.
