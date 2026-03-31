#!/bin/bash
#SBATCH --job-name=launch_isoquant
#SBATCH --output=launch_isoquant-%j.out
#SBATCH --partition=pi_hall
#SBATCH --constraint=nogpu
#SBATCH --cpus-per-task=2
#SBATCH --mem=5G
#SBATCH --time=28-00:00:00

module purge
module load Nextflow/24.04.4

SAMPLE_SHEET="samplesheet.csv"
REF_FASTA="/gpfs/gibbs/pi/ycgh/wl474/resources/reference_genomes/GRCh38_no_alt/GRCh38_no_alt.fa"
REF_FAI="/gpfs/gibbs/pi/ycgh/wl474/resources/reference_genomes/GRCh38_no_alt/GRCh38_no_alt.fa.fai"
EXTENDED_GTF="/gpfs/gibbs/pi/ycgh/wl474/projects/hprc_r2/isoform_analysis/isoquant_v3.8.0/second_pass/extended_annotation/HPRC_R2_FLNC.extended_annotation.gtf"
OUTDIR="results"

nextflow run main.nf \
    -ansi-log true \
    -profile mccleary \
    --sample_sheet ${SAMPLE_SHEET} \
    --ref_fasta ${REF_FASTA} \
    --ref_fai ${REF_FAI} \
    --extended_gtf ${EXTENDED_GTF} \
    --outdir ${OUTDIR}
