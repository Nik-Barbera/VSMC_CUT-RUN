#!/bin/bash

# Directory to the genome .fa file
GENOME=/nv/vol192/civeleklab/Nik/Genome_assemblies/hg38/hg38.fa

# Load modules
module purge
module load gcc
module load samtools

samtools faidx $GENOME
# print the first and second column separated by a tab
awk -v OFS='\t' {'print $1,$2'} $GENOME.fai > GRCh38_genome.txt
