#!/bin/bash
#SBATCH --job-name=launch_gffread
#SBATCH --output=launch_gffread-%j.out
#SBATCH --partition=pi_hall
#SBATCH --constraint=nogpu
#SBATCH --cpus-per-task=2
#SBATCH --mem=5G
#SBATCH --time=7-00:00:00

module purge
module load Nextflow/24.04.4

OUTDIR="results"
REF_FASTA="/gpfs/gibbs/pi/ycgh/wl474/resources/reference_genomes/GRCh38_no_alt/GRCh38_no_alt.fa"
REF_FAI="/gpfs/gibbs/pi/ycgh/wl474/resources/reference_genomes/GRCh38_no_alt/GRCh38_no_alt.fa.fai"
TRANSCRIPT_GTF="/gpfs/gibbs/pi/ycgh/wl474/projects/hprc_r2/isoform_analysis/final_extended_annotation/HPRC_R2_FLNC.final_extended_annotation.gtf"

nextflow run main.nf \
    -ansi-log true \
    -profile mccleary \
    --outdir ${OUTDIR} \
    --ref_fasta ${REF_FASTA} \
    --ref_fai ${REF_FAI} \
    --transcript_gtf ${TRANSCRIPT_GTF}
