#!/bin/bash
#SBATCH -A civeleklab
#SBATCH -o Out
#SBATCH -e Error
#SBATCH -o 03_Alignment_%j.out
#SBATCH -e 03_Alignment_%j.err
#SBATCH -p standard	# partition/queue
#SBATCH --nodes=1		# number of compute nodes
#SBATCH --ntasks=1		# number of program instances
#SBATCH --time=06:00:00		# max time before job cancels
#SBATCH --mem=64GB               # memory
#SBATCH --cpus-per-task=8
#SBATCH --array=0-83

# Create directory and set variables
DATA_PATH=/nv/vol192/civeleklab/Nik/CUTRUN/FullExperiment_2023/trim_galore_reads
GENOME_INDEX_PATH=/nv/vol192/civeleklab/Nik/Genome_assemblies/hg38_bidx
OUTDIR=/nv/vol192/civeleklab/Nik/CUTRUN/FullExperiment_2023/aligned_reads

# Make output directory if it doesn't exist.
if [ ! -d "$OUTDIR" ]; then
  mkdir $OUTDIR
fi

cd $DATA_PATH
# Get list of all data files
#NOTE: Your trimmed files may have different names, double check

FILES_FOR=($(ls -1 *R1_001_val_1.fq.gz))
FILES_REV=($(ls -1 *R2_001_val_2.fq.gz))

# Use Slurm Array number 
#to select file for this job
FILE_FOR=${FILES_FOR[$SLURM_ARRAY_TASK_ID]}
FILE_REV=${FILES_REV[$SLURM_ARRAY_TASK_ID]}
SAMPLE_ID=($(basename ${FILE_FOR%%_S*}))


echo "Processing file $FILE_FOR and $FILE_REV"
echo "Sample ID: $SAMPLE_ID"
start=$SECONDS
module purge
module load gcc
module load bowtie2
module load samtools

# NOTE: --end-to-end because trimming was done prior
#       --very-sensitive to enhance sensitivity

# This command is a little data-intensive and inefficient. It's organized the way
# it is so that it spits out the .txt file, which is used in the QC script in R

# NOTE: the specific command flags here were chosen based on reading different papers and protocols 
# in the literature. There doesn't appear to be a consensus and ymmv

bowtie2 \
-p $SLURM_CPUS_PER_TASK --end-to-end --very-sensitive --no-unal \
--no-mixed --no-discordant --phred33 -I 10 -X 700 \
-x $GENOME_INDEX_PATH/hg38 \
-1 $FILE_FOR -2 $FILE_REV -S $OUTDIR/$SAMPLE_ID.sam &> $OUTDIR/${SAMPLE_ID}_bowtie2.txt

samtools sort $OUTDIR/$SAMPLE_ID.sam -m 64G -o $OUTDIR/$SAMPLE_ID.bam 
rm $OUTDIR/$SAMPLE_ID.sam

end=$SECONDS
echo "duration:$((end-start)) seconds."
