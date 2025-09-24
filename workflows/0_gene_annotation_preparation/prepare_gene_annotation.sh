#!/usr/bin/env bash
set -euo pipefail

ASM_REPORT_LINK='https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/001/405/GCA_000001405.29_GRCh38.p14/GCA_000001405.29_GRCh38.p14_assembly_report.txt'
GENCODE_LINK='https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_48/gencode.v48.primary_assembly.annotation.gtf.gz'
PREFIX='gencode.v48.primary.ucscstyle'

# 1. Download inputs
wget -nv -O assembly_report.txt "$ASM_REPORT_LINK"
wget -nv -O gencode.gtf.gz "$GENCODE_LINK"

# 2. Build map: only unlocalized/unplaced scaffolds with UCSC names
awk -F'\t' 'BEGIN{OFS="\t"}
  { sub(/\r$/, "", $0) }
  !/^#/ && ($2=="unlocalized-scaffold" || $2=="unplaced-scaffold") && $10!="na" { print $5, $10 }
' assembly_report.txt > scaffold_genbank_to_ucsc.tsv

# 3. Rename only those seqnames in the GTF
gzip -dc gencode.gtf.gz | \
awk -F'\t' 'BEGIN{OFS="\t"}
  FNR==NR { map[$1]=$2; next }
  /^#/ { print; next }
  ($1 in map) { $1 = map[$1] }
  { print }
' scaffold_genbank_to_ucsc.tsv - | gzip -c > "${PREFIX}.gtf.gz"

# 4. Convert GTF -> BED12
gzip -dc "${PREFIX}.gtf.gz" | paftools.js gff2bed - > "${PREFIX}.bed"

# 5. Cleanup
rm -f assembly_report.txt scaffold_genbank_to_ucsc.tsv gencode.gtf.gz

echo "Done:"
echo "  ${PREFIX}.gtf.gz"
echo "  ${PREFIX}.bed"
