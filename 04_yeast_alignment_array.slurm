#!/bin/bash
#SBATCH -A civeleklab
#SBATCH -o Out
#SBATCH -e Error
#SBATCH -p standard
#SBATCH -o 04_yeast_align_%j.out
#SBATCH -e 04_yeast_align_%j.err
#SBATCH --nodes=1		# number of compute nodes
#SBATCH --ntasks=1		# number of program instances
#SBATCH --time=02:00:00		# max time before job cancels
#SBATCH --mem=64GB               # memory
#SBATCH --cpus-per-task=8
#SBATCH --array=0-83

# Create directory and set variables
DATA_PATH=/nv/vol192/civeleklab/Nik/CUTRUN/FullExperiment_2023/trim_galore_reads
GENOME_INDEX_PATH=/nv/vol192/civeleklab/Nik/Genome_assemblies/R64-1-1
OUTDIR=/nv/vol192/civeleklab/Nik/CUTRUN/FullExperiment_2023/yeast_aligned_reads

# Make output directory if it doesn't exist.
if [ ! -d "$OUTDIR" ]; then
  mkdir $OUTDIR
fi

cd $DATA_PATH
# Get list of all data files
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

bowtie2 \
-p $SLURM_CPUS_PER_TASK --local --very-sensitive-local --no-unal \
--no-mixed --no-discordant --phred33 -I 10 -X 700  \
--no-overlap --no-dovetail \
-x $GENOME_INDEX_PATH/R64-1-1 \
-1 $FILE_FOR -2 $FILE_REV -S $OUTDIR/${SAMPLE_ID}_bowtie2_spikeIn.sam &> $OUTDIR/${SAMPLE_ID}_bowtie2_spikeIn.txt 

seqDepthDouble=`samtools view -F 0x04 $OUTDIR/${SAMPLE_ID}_bowtie2_spikeIn.sam | wc -l`
seqDepth=$((seqDepthDouble/2))
echo $seqDepth > $OUTDIR/${SAMPLE_ID}_bowtie2_spikeIn.seqDepth

samtools sort $OUTDIR/${SAMPLE_ID}_bowtie2_spikeIn.sam -m 64G -o $OUTDIR/${SAMPLE_ID}_bowtie2_spikeIn.bam
rm $OUTDIR/${SAMPLE_ID}_bowtie2_spikeIn.sam

end=$SECONDS
echo "duration:$((end-start)) seconds."
