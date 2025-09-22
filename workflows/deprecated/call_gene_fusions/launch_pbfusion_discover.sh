#!/bin/bash
#SBATCH --job-name=launch_pbfusion_discover
#SBATCH --output=launch_pbfusion_discover-%j.out
#SBATCH --partition=pi_hall
#SBATCH --constraint=nogpu
#SBATCH --cpus-per-task=2
#SBATCH --mem=5G
#SBATCH --time=14-00:00:00

module purge
module load Nextflow/24.04.4

SAMPLE_SHEET="samplesheet.csv"
GTF="/gpfs/gibbs/pi/ycgh/wl474/resources/reference_genomes/GRCh38_no_alt/isoseq/gencode_v39/gencode.v39.annotation.sorted.gtf.bin"
OUTDIR="results"

nextflow run main.nf \
    -ansi-log true \
    -profile mccleary \
    --sample_sheet ${SAMPLE_SHEET} \
    --gtf ${GTF} \
    --outdir ${OUTDIR}
