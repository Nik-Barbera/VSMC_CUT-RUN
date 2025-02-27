#!/bin/bash
#SBATCH -A civeleklab
#SBATCH -o Out
#SBATCH -e Error
#SBATCH -p standard
#SBATCH -o 02_TrimGalore_%j.out
#SBATCH -e 02_TrimGalore_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=unz2ra@virginia.edu
#SBATCH --nodes=1		# number of compute nodes
#SBATCH --ntasks=1		# number of program instances
#SBATCH --time=05:00:00		# max time before job cancels
#SBATCH --mem=9GB               # memory
#SBATCH -c 16
#SBATCH --array=0-83

DATA_PATH=/nv/vol192/civeleklab/Nik/CUTRUN/FullExperiment_2023/Data
OUTDIR=/nv/vol192/civeleklab/Nik/CUTRUN/FullExperiment_2023/trim_galore_reads
OUTQ=/nv/vol192/civeleklab/Nik/CUTRUN/FullExperiment_2023/trim_galore_reads/fastqc

# Make output directory if it doesn't exist.
if [ ! -d "$OUTDIR" ]; then
  mkdir $OUTDIR
fi

# Make fastqc output directory if it doesn't exist.
if [ ! -d "$OUTQ" ]; then
  mkdir $OUTQ
fi


# Get list of all data files
FILES_FOR=($(ls -1 $DATA_PATH/*R1_001.fastq.gz))
FILES_REV=($(ls -1 $DATA_PATH/*R2_001.fastq.gz))

# Use Slurm Array number 
#to select file for this job
FILE_FOR=${FILES_FOR[$SLURM_ARRAY_TASK_ID]}
FILE_REV=${FILES_REV[$SLURM_ARRAY_TASK_ID]}

echo "Processing file $FILE_FOR and $FILE_REV"
start=$SECONDS
module purge
module load trimgalore/0.6.4

trim_galore --cores 4 --nextseq 20 --length 20 --paired \
--fastqc_args "--outdir $OUTQ" --illumina --output_dir $OUTDIR $FILE_FOR $FILE_REV

end=$SECONDS
echo "duration:$((end-start)) seconds."
