#!/bin/bash

# Define the directory containing chromosome fasta files
CHROMOSOME_DIR="/home/tianchuw/ha22_scratch/CapeWeed_Hap/Chromosome_Dir"
PROTEINS="/home/tianchuw/ha22_scratch/CapeWeed_Hap/allProteins.fasta"
ANNOTATION_DIR="/home/tianchuw/ha22_scratch/CapeWeed_Hap/Annotation" 
GENEMARK="/usr/local/genemark/4.30"
PROTHINT="/usr/local/prothint/2.6.0"
LOG_DIR="/home/tianchuw/ha22_scratch/CapeWeed_Hap/Log_Dir/braker_protein_chromosomes"

# New directory for storing BRAKER protein output per chromosome
BRAKER_CHROMOSOME_DIR="${ANNOTATION_DIR}/braker_protein_chromosomes"

# Ensure the new output directory for BRAKER exists
mkdir -p "${BRAKER_CHROMOSOME_DIR}"
mkdir -p "${LOG_DIR}"

# Specify the chromosome to rerun
RERUN_CHROMOSOMES=(
"tom-mon3828-mb-hirise-yv4r5__06-15-2023__final_assembly_top9.fasta.masked_Scaffold_1__1_contigs__length_62925999.fasta"
"tom-mon3828-mb-hirise-yv4r5__06-15-2023__final_assembly_top9.fasta.masked_Scaffold_2__1_contigs__length_69447999.fasta"
)

# Iterate over each chromosome fasta file and submit a Braker job only for specified chromosomes
for CHROMOSOME_FASTA in ${CHROMOSOME_DIR}/*.fasta; do
    CHROMOSOME_NAME=$(basename "${CHROMOSOME_FASTA}")
    
    # Check if the current chromosome is in the list of chromosomes to rerun
    if [[ " ${RERUN_CHROMOSOMES[@]} " =~ " ${CHROMOSOME_NAME} " ]]; then
        sbatch <<- EOF
		#!/bin/bash
		#SBATCH -J Braker_Protein_${CHROMOSOME_NAME}
		#SBATCH -o ${LOG_DIR}/${CHROMOSOME_NAME}.out
		#SBATCH -e ${LOG_DIR}/${CHROMOSOME_NAME}.err
		#SBATCH -n 30
		#SBATCH --mem-per-cpu=30G  # Increased memory per CPU
		#SBATCH -t 7-00:00:00     # Extended time limit

		# Load modules
		module load braker3/3.0.3
		module load genemark/4.30
		module load prothint/2.6.0

		# Define species name
		SPECIES="Arctotheca calendula, Asteraceae prot"

		# Running BRAKER in protein-mode for the specified chromosome
		echo "Running BRAKER in protein-mode for ${CHROMOSOME_NAME}..."
		braker.pl --genome=${CHROMOSOME_FASTA} \
			  --prot_seq ${PROTEINS} \
		          --softmasking \
		          --useexisting \
		          --GENEMARK_PATH=${GENEMARK} \
			  --PROTHINT_PATH ${PROTHINT} \
		          --threads=30 \
		          --workingdir=${BRAKER_CHROMOSOME_DIR}/${CHROMOSOME_NAME} \
		          --species="${SPECIES}_${CHROMOSOME_NAME}" 2>${LOG_DIR}/${CHROMOSOME_NAME}.log
	EOF
	fi
done