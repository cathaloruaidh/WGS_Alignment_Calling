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




### Create Sequence Dictionary for Reference FASTA file
# Run the picard command

if [ ! -f ${REF_FASTA%fa}dict ]
then
	java ${JAVA_OPTIONS} -jar ${PICARD_FILE} CreateSequenceDictionary \
		REFERENCE=${REF_FASTA} \
		OUTPUT=${REF_FASTA%fa}dict \
		2> >( tee ${LOG_DIR}/${OUTPUT_PREFIX}.ALIGN.${1}.log >&2 )
else
	log "Dictionary sequence for reference file already exists. " 3
fi


DICT_RET=$?



# If the dictionary creation gave an error, exit with error
if [ $DICT_RET -ne 0 ]
then
	exit 15
fi
