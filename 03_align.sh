#!/bin/bash

############################################################
#
# Assembly of NGS data from FASTQ to GVCF 
# Cathal Ormond 2017. 
#
# Alignment of reads from FASTQ file to reference genome
#
# Based loosely on scripts found here:
# https://github.com/genepi-freiburg/gwas
#
############################################################




### Align the reads to the reference genome, and convert to a BAM
# Run the BWA and samtools commands

bwa mem \
	-R "@RG\tID:${SOURCE_FILE}\tSM:${SOURCE_FILE}\tPL:ILLUMINA" \
	-t ${NPROCS} \
	-c 250 \
	-M \
	-v 1 ${GRCH38} ${READ1} ${READ2} \
	| samtools view -Sb -h - > ${RESULTS_DIR}/${BAM}

MAP_RET=$?



# If the alignment gave an error, exit with an error
if [ $MAP_RET -ne 0 ]
then
	exit 15
fi



