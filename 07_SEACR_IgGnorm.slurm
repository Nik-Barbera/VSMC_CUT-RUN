#!/bin/bash
#SBATCH -A civeleklab
#SBATCH -o Out
#SBATCH -e Error
#SBATCH -o 07_SEACR_wFBS_%j.out
#SBATCH -e 07_SEACR_wFBS_%j.err
#SBATCH -p standard	# partition/queue
#SBATCH --nodes=1		# number of compute nodes
#SBATCH --ntasks=1		# number of program instances
#SBATCH --time=04:00:00		# max time before job cancels
#SBATCH --mem=32GB               # memory
#SBATCH --cpus-per-task=8

cd /nv/vol192/civeleklab/Nik/CUTRUN/FullExperiment_2023/Analysis_Pipeline_Scripts

# Create directory and set variables
BEDGRAPH_FILES_PATH=/nv/vol192/civeleklab/Nik/CUTRUN/FullExperiment_2023/normalized_bedgraphs
OUTDIR=/nv/vol192/civeleklab/Nik/CUTRUN/FullExperiment_2023/SEACR_IgGNorm_Peaks

# Make output directory if it doesn't exist.
if [ ! -d "$OUTDIR" ]; then
  mkdir $OUTDIR
fi


# NOTE: there's probably a way to write this more efficiently for slurm batch scripting
# but this runs quick enough.

# Define all samples/donors and Histone/TF marks EXCEPT the negative control.
Samples=("L101_wFBS" "F93_wFBS" "K101_wFBS" "C99_wFBS" "W87_wFBS" "G96_wFBS")
Hist=("_H3K4me3" "_H3K27ac" "_H2BK20ac" "_Input")


module purge
module load gcc/9.2.0 openmpi/3.1.6 R/4.2.1
module load bedtools/2.29.2
module load seacr/1.3

for str in ${Samples[@]}; do
	for his in ${Hist[@]}; do
		start=$SECONDS
		SAMPLE_ID=(${str}${his})
		IgG_ID=(${str}_IgG)
		echo "Running SEACR for: $SAMPLE_ID"
		echo "IgG Control: $IgG_ID"

		FILE=(${BEDGRAPH_FILES_PATH}/${SAMPLE_ID}.fragments.normalized.bedgraph)
		IgG_FILE=(${BEDGRAPH_FILES_PATH}/${IgG_ID}.fragments.normalized.bedgraph)
		
		bash SEACR_1.3.sh $FILE $IgG_FILE non stringent $OUTDIR/${SAMPLE_ID}_IgGNorm.peaks

		bash SEACR_1.3.sh $FILE 0.01 non stringent $OUTDIR/${SAMPLE_ID}_top0.01.peaks
		
		end=$SECONDS
		echo "duration:$((end-start)) seconds."

	done 
done



