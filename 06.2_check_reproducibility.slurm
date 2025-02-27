#!/bin/bash

#SBATCH -A civeleklab
#SBATCH -p standard
#SBATCH -o 06.2_check_reproducibility_%j.out
#SBATCH -e 06.2_check_reproducibility_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=unz2ra@virginia.edu
#SBATCH --nodes=1		# number of compute nodes
#SBATCH --ntasks=1		# number of program instances
#SBATCH --time=02:00:00		# max time before job cancels
#SBATCH --mem=64GB               # memory
#SBATCH --cpus-per-task=8
#SBATCH --array=0-83


# Create directory and set variables
DATA_PATH=/nv/vol192/civeleklab/Nik/CUTRUN/FullExperiment_2023/normalized_bed
OUTDIR=/nv/vol192/civeleklab/Nik/CUTRUN/FullExperiment_2023/normalized_bed
OUTFRAGBIN=/nv/vol192/civeleklab/Nik/CUTRUN/FullExperiment_2023/normalized_bed/fragmentLen


# Make output directory if it doesn't exist.
if [ ! -d "$OUTFRAGBIN" ]; then
  mkdir $OUTFRAGBIN
fi


# Get list of all bam data files
FILES=($(ls -1 $DATA_PATH/*.fragments.bed))
# Use Slurm Array number to select file for this job
FILE=${FILES[$SLURM_ARRAY_TASK_ID]}
SAMPLE_ID=($(basename ${FILE%%.fragments.bed}))

echo "Processing file $FILE"
echo "Sample ID: $SAMPLE_ID"
start=$SECONDS

binLen=500
awk -v w=$binLen '{print $1, int(($2 + $3)/(2*w))*w + w/2}' \
$OUTDIR/$SAMPLE_ID.fragments.bed \
| sort -k1,1V -k2,2n | uniq -c | awk -v OFS="\t" '{print $2, $3, $1}' \
|  sort -k1,1V -k2,2n  > $OUTFRAGBIN/${SAMPLE_ID}.fragmentsCount.bin${binLen}.bed
