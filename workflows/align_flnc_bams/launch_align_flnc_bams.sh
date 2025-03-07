#!/bin/bash
#SBATCH --job-name=launch_align_flnc_bams
#SBATCH --output=launch_align_flnc_bams-%j.out
#SBATCH --partition=pi_hall
#SBATCH --constraint=nogpu
#SBATCH --cpus-per-task=2
#SBATCH --mem=5G
#SBATCH --time=28-00:00:00

module purge
module load Nextflow/24.04.4

SAMPLE_SHEET="samplesheet.csv"
REF_MMI="/gpfs/gibbs/pi/ycgh/wl474/resources/reference_genomes/GRCh38_no_alt/isoseq/GRCh38_no_alt.isoseq.mmi"
OUTDIR="results"

nextflow run main.nf \
    -ansi-log true \
    -profile mccleary \
    --sample_sheet ${SAMPLE_SHEET} \
    --ref_mmi ${REF_MMI} \
    --outdir ${OUTDIR}
