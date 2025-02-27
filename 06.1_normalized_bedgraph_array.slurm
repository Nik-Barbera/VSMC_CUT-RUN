#!/bin/bash

#SBATCH -A civeleklab
#SBATCH -p standard
#SBATCH -o 06.1_normalized_bedgraph_array_%j.out
#SBATCH -e 06.1_normalized_bedgraph_array_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=unz2ra@virginia.edu
#SBATCH --nodes=1		# number of compute nodes
#SBATCH --ntasks=1		# number of program instances
#SBATCH --time=02:00:00		# max time before job cancels
#SBATCH --mem=64GB               # memory
#SBATCH --cpus-per-task=8
#SBATCH --array=0-83

cd /nv/vol192/civeleklab/Nik/CUTRUN/FullExperiment_2023/Analysis_Pipeline_Scripts

# Create directory and set variables
DATA_PATH=/nv/vol192/civeleklab/Nik/CUTRUN/FullExperiment_2023/aligned_reads
OUTDIR=/nv/vol192/civeleklab/Nik/CUTRUN/FullExperiment_2023/normalized_bed
OUTFRAG=/nv/vol192/civeleklab/Nik/CUTRUN/FullExperiment_2023/aligned_reads/frag_length
OUTBEDGRAPH=/nv/vol192/civeleklab/Nik/CUTRUN/FullExperiment_2023/normalized_bedgraphs
OUTBW=/nv/vol192/civeleklab/Nik/CUTRUN/FullExperiment_2023/normalized_bigwigs


# Make output directory if it doesn't exist.
if [ ! -d "$OUTDIR" ]; then
  mkdir $OUTDIR
fi
if [ ! -d "$OUTBEDGRAPH" ]; then
  mkdir $OUTBEDGRAPH
fi
if [ ! -d "$OUTFRAG" ]; then
  mkdir $OUTFRAG
fi
if [ ! -d "$OUTBW" ]; then
  mkdir $OUTBW
fi


# Get list of all bam data files
FILES=($(ls -1 $DATA_PATH/*.bam))
readarray -t SCALE_FACTORS < Scale_factors.txt

# Use Slurm Array number to select file for this job
FILE=${FILES[$SLURM_ARRAY_TASK_ID]}
SAMPLE_ID=($(basename ${FILE%%.bam}))
SCALE_FACTOR=${SCALE_FACTORS[$SLURM_ARRAY_TASK_ID]}

echo "Processing file $FILE"
echo "Sample ID: $SAMPLE_ID"
echo "Scale factor: $SCALE_FACTOR"
start=$SECONDS
module purge
module load gcc
module load samtools
module load bedtools
module load java
module load picard

## Extract the 9th column from the alignment bam file which is the fragment length
samtools view -F 0x04 $FILE | awk -F'\t' 'function abs(x){return ((x < 0.0) ? -x : x)} {print abs($9)}' | sort | uniq -c | awk -v OFS="\t" '{print $2, $1/2}' >$OUTFRAG/${SAMPLE_ID}_fragmentLen.txt

# Sort by name and mark duplicates
samtools sort -@ 8 -o $OUTDIR/$SAMPLE_ID.sorted.bam $FILE
java -jar $EBROOTPICARD/picard.jar MarkDuplicates -REMOVE_DUPLICATES true -I $OUTDIR/$SAMPLE_ID.sorted.bam -O $OUTDIR/$SAMPLE_ID.dupfiltered.bam -M $OUTDIR/$SAMPLE_ID.metrics.txt

# Filtering out reads with less than 20 MAPQ score
samtools sort -n -@ 8 $OUTDIR/$SAMPLE_ID.dupfiltered.bam > $OUTDIR/$SAMPLE_ID.namesorted.bam
samtools view -h -q 30 -f 2 $OUTDIR/$SAMPLE_ID.namesorted.bam > $OUTDIR/$SAMPLE_ID.dupqppfiltered.bam

# Converting a paired-bed BAM file to paired end BED file
bedtools bamtobed -bedpe -i $OUTDIR/$SAMPLE_ID.dupqppfiltered.bam > $OUTDIR/$SAMPLE_ID.bed

# Selecting the 5' and 3' coordinates of the read pair to generate a new BED3 file
awk '$1==$4 && $6-$2 < 1000 {print $0}' $OUTDIR/$SAMPLE_ID.bed > $OUTDIR/$SAMPLE_ID.clean.bed
cut -f 1,2,6 $OUTDIR/$SAMPLE_ID.clean.bed | sort -k1,1 -k2,2n -k3,3n | grep -v "^\." > $OUTDIR/$SAMPLE_ID.fragments.bed

# Converting sorted BAM file to a bedgraph using bedtools genomecov
bedtools genomecov -bg -scale $SCALE_FACTOR -i $OUTDIR/$SAMPLE_ID.fragments.bed -g GRCh38_genome.txt > $OUTBEDGRAPH/$SAMPLE_ID.fragments.normalized.bedgraph

# Converts bedgraph to bigwig for easier viewing in IGV
bedGraphToBigWig $OUTBEDGRAPH/$SAMPLE_ID.fragments.normalized.bedgraph
 https://hgdownload.cse.ucsc.edu/goldenPath/hg38/bigZips/hg38.chrom.sizes $OUTBW/${SAMPLE_ID}.bw

end=$SECONDS
echo "duration:$((end-start)) seconds."
