#!/bin/bash

#SBATCH --time=1:00:00
#SBATCH -A civeleklab
#SBATCH -o Out
#SBATCH -e Error
#SBATCH -p standard
#SBATCH -o fastqc_%j.out
#SBATCH -e fastqc_%j.err
#SBATCH --array=0-167

module purge
module load fastqc/0.11.5

DATA_PATH=/nv/vol192/civeleklab/Nik/CUTRUN/FullExperiment_2023/Data
OUTDIR=/nv/vol192/civeleklab/Nik/CUTRUN/FullExperiment_2023/fastqc_output_array

# Make output directory if it doesn't exist.
if [ ! -d "$OUTDIR" ]; then
  mkdir $OUTDIR
fi

# Get list of all data files
FILES=($(ls -1 $DATA_PATH/*.fastq.gz))

# Use Slurm Array number 
#to select file for this job
FILE=${FILES[$SLURM_ARRAY_TASK_ID]}

echo "Processing file $FILE"

fastqc $FILE --outdir $OUTDIR 

