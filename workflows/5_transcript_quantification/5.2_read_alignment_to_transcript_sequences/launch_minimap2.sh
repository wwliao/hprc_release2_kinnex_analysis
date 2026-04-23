#!/bin/bash
#SBATCH --job-name=launch_minimap2
#SBATCH --output=launch_minimap2-%j.out
#SBATCH --partition=pi_hall
#SBATCH --constraint=nogpu
#SBATCH --cpus-per-task=2
#SBATCH --mem=5G
#SBATCH --time=7-00:00:00

module purge
module load Nextflow/24.04.4

SAMPLE_SHEET="samplesheet.csv"
OUTDIR="results"
TRANSCRIPT_FASTA="/gpfs/gibbs/pi/ycgh/wl474/projects/hprc_r2/isoform_analysis/oarfish/gffread/results/HPRC_R2_FLNC.final_extended_annotation.fa"

nextflow run main.nf \
    -ansi-log true \
    -profile mccleary \
    --sample_sheet ${SAMPLE_SHEET} \
    --transcript_fasta ${TRANSCRIPT_FASTA} \
    --outdir ${OUTDIR}
