#!/bin/bash
#SBATCH --job-name=launch_classify_transcripts
#SBATCH --output=launch_classify_transcripts-%j.out
#SBATCH --partition=pi_hall
#SBATCH --constraint=nogpu
#SBATCH --cpus-per-task=2
#SBATCH --mem=5G
#SBATCH --time=28-00:00:00

module purge
module load Nextflow/24.04.4

SAMPLE_SHEET="samplesheet.csv"
ANNO_GTF="/gpfs/gibbs/pi/ycgh/wl474/resources/reference_genomes/GRCh38_no_alt/isoseq/gencode_v39/gencode.v39.annotation.sorted.gtf"
ANNO_PGI="/gpfs/gibbs/pi/ycgh/wl474/resources/reference_genomes/GRCh38_no_alt/isoseq/gencode_v39/gencode.v39.annotation.sorted.gtf.pgi"
REF_FASTA="/gpfs/gibbs/pi/ycgh/wl474/resources/reference_genomes/GRCh38_no_alt/isoseq/gencode_v39/GRCh38_no_alt.fa"
REF_FAI="/gpfs/gibbs/pi/ycgh/wl474/resources/reference_genomes/GRCh38_no_alt/isoseq/gencode_v39/GRCh38_no_alt.fa.fai"
CAGE_BED="/gpfs/gibbs/pi/ycgh/wl474/resources/reference_genomes/GRCh38_no_alt/isoseq/gencode_v39/refTSS_v3.3_human_coordinate.hg38.sorted.bed"
CAGE_PGI="/gpfs/gibbs/pi/ycgh/wl474/resources/reference_genomes/GRCh38_no_alt/isoseq/gencode_v39/refTSS_v3.3_human_coordinate.hg38.sorted.bed.pgi"
POLYA="/gpfs/gibbs/pi/ycgh/wl474/resources/reference_genomes/GRCh38_no_alt/isoseq/gencode_v39/polyA.list.txt"
JUNCTION_TSV="/gpfs/gibbs/pi/ycgh/wl474/resources/reference_genomes/GRCh38_no_alt/isoseq/gencode_v39/intropolis.v1.hg19_with_liftover_to_hg38.tsv.min_count_10.modified2.sorted.tsv"
JUNCTION_PGI="/gpfs/gibbs/pi/ycgh/wl474/resources/reference_genomes/GRCh38_no_alt/isoseq/gencode_v39/intropolis.v1.hg19_with_liftover_to_hg38.tsv.min_count_10.modified2.sorted.tsv.pgi"
OUTDIR="results"

nextflow run main.nf \
    -ansi-log true \
    -profile mccleary \
    --sample_sheet ${SAMPLE_SHEET} \
    --anno_gtf ${ANNO_GTF} \
    --anno_pgi ${ANNO_PGI} \
    --ref_fasta ${REF_FASTA} \
    --ref_fai ${REF_FAI} \
    --cage_bed ${CAGE_BED} \
    --cage_pgi ${CAGE_PGI} \
    --polya ${POLYA} \
    --junction_tsv ${JUNCTION_TSV} \
    --junction_pgi ${JUNCTION_PGI} \
    --outdir ${OUTDIR}
