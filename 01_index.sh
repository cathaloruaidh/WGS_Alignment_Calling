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




### Index the Reference FASTA file
# Run the BWA command


if [ ! -f ${REF_FASTA}.amb ] || [ ! -f ${REF_FASTA}.ann ] || [ ! -f ${REF_FASTA}.bwt ] || [ ! -f ${REF_FASTA}.pac ] || [ ! -f ${REF_FASTA}.sa ]
then
	${BWA} index ${REF_FASTA}
else
	log "Index files for reference file already exist. " 3
fi

IDX_RET=$?



# If the indexing gave an error, exit with error
if [ $IDX_RET -ne 0 ]
then
	exit 15
fi


