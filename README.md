# VSMC_CUT-RUN
This repo contains the code use to analyze the data collected from CUT&RUN assays performed on VSMCs for BioRxiv 10.1101/2024.10.07.617126
Currently, it is a collection of files used for the SLURM workload manager. As is, these scripts assume the user has 84 samples that they 
are running analysis in parallel on. Change the "#SBATCH --array=0-83" line as needed.

This pipeline assumes that the following modules are loaded:
fastqc/0.11.5
multiqc/1.14 (if summarizing all outputs)
trimgalore/0.6.4
bedtools/2.30.0
samtools/1.17
java/21
picard/2.27.5
seacr/1.3 (and associated R script from SEACR authors)


# Analysis Pipeline for CUT&RUN

The basic workflow is:

**script 01: Run fastqc on fastq sequencing files**
- You can summarize all outputs with MultiQC

**script 02: Trim reads with TrimGalore**
- You can summarize all outputs with MultiQC

**script 03: Align reads to Human genome with Bowtie2**
- NOTE: You will need to provide file path to local human genome fasta file

**script 04: Align reads to spike-in genome with Bowtie2**
- Can be E. Coli, R64-1-1 yeast, depending on  (as written, the script assues R64-1-1)
- this will generate a text file of scale factors
    
**script 05: run sh 05.0_genome_file.sh to create txt file listing chromosome lengths. (used in 06)**
 
**script 06.1: Generating control-normalized bedgraphs from aligned reads**
1. Get fragment lengths for QC
2. Sort bam file, remove duplicates
3. Convert bam file to bed file
4. Check bed is in correct format, remove reads > 1000 bp, sort
5. Convert filtered bam file into bedgraph, noramlized by IgG control and scaled with scale factor
6. Convert bedgraph to bigwig for easier viewing in IGV

**script 06.2: [for QC] Bins the reads in bed file generated in 06.1 so that replicates can be compared to check reproducibility**

**script 07: SEACR peak calling**
- NOTE: User will have to edit the code to list the specific samples and histone modificatios/TFs they want to run through the loop.

## Sources used for pipeline dev:

- https://yezhengstat.github.io/CUTTag_tutorial/index.html#VIII_Differential_analysis
- https://data.4dnucleome.org/resources/data-analysis/cut-and-run-pipeline
- "cBAF complex components and MYC cooperate early in CD8+ T cell fate"
- "CRISPR and biochemical screens identify MAZ as a cofactor in CTCF-mediated insulation at Hox clusters" 
- "Genome-wide profiling of histone H3K4me3 and H3K27me3 modifications in individual blastocysts by CUT&Tag without a solid support (NON-TiE-UP CUT&Tag)"
