#!/bin/bash

############################################################
#
# Assembly of NGS data from FASTQ to GVCF 
# Cathal Ormond 2017. 
#
# Alignment of reads from FASTQ file to reference genome
#
# Based losely on scripts found here:
# https://github.com/genepi-freiburg/gwas
#
############################################################




### Validate the BAM file before any further processing
# Run the picard command


java ${JAVA_OPTIONS} -jar ${PICARD_FILE} ValidateSamFile \
	I=${RESULTS_DIR}/${SORT_BAM} \
	O=${RESULTS_DIR}/${FIRST_VAL} \
	MODE=SUMMARY \
	MAX_OUTPUT=null \
	TMP_DIR=${TEMP_DIR}


VAL_RET=$?


log "Validation File: " 3
log "$(cat ${RESULTS_DIR}/${FIRST_VAL})" 3 


# If the validation gave an error, exit with error
if [ $VAL_RET -ne 0 ] 
then
	exit 15
fi
