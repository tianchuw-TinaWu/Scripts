#####
# Tina- BUSCO analysis
#####

# change directory to the NEW location of the capeweed genome
cd ~/ha22_scratch/CapeWeed_Hap/

# here is the assembly (with probably lots of contamination)
ls tom-mon3828-mb-hirise-yv4r5__06-15-2023__final_assembly.fasta

### use samtools to extract the nine largest scaffolds
# I've already run this code but I have included it so you can see how to do it:

# load the samtools module
module load samtools

# first we need a FASTA index (FAI) file
samtools faidx tom-mon3828-mb-hirise-yv4r5__06-15-2023__final_assembly.fasta

# you can see the index here
ls tom-mon3828-mb-hirise-yv4r5__06-15-2023__final_assembly.fasta.fai

# this gives us the nine largest scaffolds
# (sort by the second column [-k2], which is the contig size, and then take the last nine lines)
# 1st column - contig identity; 2nd - contig size; 3rd - position of the contig start in bytes; 4th - number of bases in each line; 5th - number of bases in each line in bytes
cat tom-mon3828-mb-hirise-yv4r5__06-15-2023__final_assembly.fasta.fai | sort -k2 -n | tail -n 9

# cat: display the contents of files.
# | (Pipe Symbol): take the output of the command on its left and use it as the input for the command on its right. 
# sort -k2 -n:
	# sort: sort lines of text files. 
	# -k2: sort based on the second column of the input.
	# -n: sort numerically.
# tail -n 9:
	# tail: display the last few lines of a file. 
	# -n 9: display the last 9 lines of the sorted output.


# save the name of these contigs (first column) to a file
# (awk prints the first column [$1])
cat tom-mon3828-mb-hirise-yv4r5__06-15-2023__final_assembly.fasta.fai | sort -k2 -n | tail -n 9 | awk '{print $1}' > top9.txt

# awk: process the input received from the previous command.
# '{print $1}': instruct awk to print the first column of each input line.


# use the list of nine contigs to extract these sequences from the assembly
samtools faidx tom-mon3828-mb-hirise-yv4r5__06-15-2023__final_assembly.fasta -r top9.txt > tom-mon3828-mb-hirise-yv4r5__06-15-2023__final_assembly_top9.fasta

# -r top9.txt: -r specify regions of interest; use the input of the top9.txt file to locate the specific regions (contigs/scaffolds) in the indexed fasta file

# to get the scaffolds except for the top 9 scaffolds
# cat tom-mon3828-mb-hirise-yv4r5__06-15-2023__final_assembly.fasta.fai | sort -k2 -n | head -n -9 | awk '{print $1}' > except_top9.txt
# samtools faidx tom-mon3828-mb-hirise-yv4r5__06-15-2023__final_assembly.fasta -r except_top9.txt > tom-mon3828-mb-hirise-yv4r5__06-15-2023__final_assembly_except_top9.fasta


# I ran the code up to here
# you can see the two FASTA files in the directory using:
ls *.fasta

### Now we want to run BUSCO for both FASTA files
# (the whole assembly and only the nine biggest contigs)
# to see if there's much difference in completeness

# here is a script to run BUSCO for the whole assembly
# you can see the assembly FASTA listed after the -i flag
# the -o flag tells us what the output directory for this run will be called

#!/bin/bash
# A shebang line. It specifies the interpreter to be used for running the script. This script will be interpreted and executed using the Bash shell. '/bin/bash' is the path to the Bash shell, other interpreters or languages can be used:
	# Python: #!/usr/bin/python (written in Python 2.x). Python 3.x: #!/usr/bin/python3.
	# Perl: #!/usr/bin/perl
	# Ruby: #!/usr/bin/ruby
	# Node.js (JavaScript): #!/usr/bin/node
	# R: #!/usr/bin/Rscript
	# PHP: #!/usr/bin/php
	# Swift: #!/usr/bin/swift

#SBATCH --job-name=busco_capeweed_all
# Set the job name for identification in the job scheduler system.

#SBATCH --time=0-20:00:00
# Specify the maximum time that the job is allowed to run. The format is D-HH:MM:SS, D-days, HH-hours, MM -minutes, SS-seconds.

#SBATCH --partition=comp
# Specify the partition or queue on the cluster where the job should be executed.

#SBATCH --nodes=1
# Specify the number of nodes required for the job.

#SBATCH --ntasks-per-node=30
# Specify the number of tasks/processes to be run on each node.

#SBATCH --mem-per-cpu=10G
Specify the memory requirement for each CPU (task) in the job. 10G - 10 gigabytes.

#SBATCH --cpus-per-task=1
# Specify the number of CPU cores to allocate per task.

#SBATCH --output=busco_capeweed_all.out
#SBATCH --error=busco_capeweed_all.err
# Specify the file names for the standard output and error streams generated by the job.


cd ~/ha22_scratch/CapeWeed_Hap/

module load busco/.5.1.3

busco \
-m genome \
-i tom-mon3828-mb-hirise-yv4r5__06-15-2023__final_assembly.fasta \
-f \
-o busco_capeweed_all \
-l eukaryota_odb10 \
--cpu 30

# \: line continuation.
# -m genome: specify the mode of analysis. genome - input genome assembly, other modes are:
	# -m proteins
	# -m transcriptome
	# -m proteins, transcriptome
	# -m meta genome
	# -m lineage
# -i: specify the input file.
# -f: overwrite the existing output files without confirmation.
# -o: specify the output directory.
# -l: specify the lineage dataset to be used for the analysis. eukaryota_odb10 - eukaryotic organisms from OrthoDB v10.
# --cpu 30: specify the number of CPU cores to be used for the analysis. 30 CPU cores for parallel processing.

###

# so if you copy this script, paste it into a file and save the file as "busco_capeweed_all.sh"
# then you can submit the job using:
sbatch busco_capeweed_all.sh

# you can check whether your job is running or not with:
show_job

# you can also keep an eye on what the program is telling you about how it is running
# by looking at the error and output logs
less busco_capeweed_all.out
less busco_capeweed_all.err

# you can run more than one job at once, so while this is running you can set up and run the
# other job, do just run BUSCO on the nine largest scaffolds

# to do this you will need to make a new job script (e.g. busco_capeweed_top9.sh)
# and change a few parameters in the script:
# firstly you need to use a different FASTA file for the -i flag
# (tom-mon3828-mb-hirise-yv4r5__06-15-2023__final_assembly_top9.fasta)
# you will also want to give a different name to the output directory for the -o flag
# finally, at the top of the script you should give the --job-name --error and --output flags
# different names

# Script for busco_capeweed_top9.sh:
# 	#!/bin/bash
# 	#SBATCH --job-name=busco_capeweed_top9
#	#SBATCH --time=0-20:00:00
#	#SBATCH --partition=comp
#	#SBATCH --nodes=1
#	#SBATCH --ntasks-per-node=30
#	#SBATCH --mem-per-cpu=10G
#	#SBATCH --cpus-per-task=1
#	#SBATCH --output=busco_capeweed_top9.out
#	#SBATCH --error=busco_capeweed_top9.err

#	cd ~/ha22_scratch/CapeWeed_Hap/

#	module load busco/.5.1.3

#	busco \
#	-m genome \
#	-i tom-mon3828-mb-hirise-yv4r5__06-15-2023__final_assembly_top9.fasta \
#	-f \
#	-o busco_capeweed_top9 \
#	-l eukaryota_odb10 \
#	--cpu 30
