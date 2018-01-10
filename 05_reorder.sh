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




### Re-order the BAM file for ease of future processing
# Run the picard command


java ${JAVA_OPTIONS} -jar ${PICARD_FILE} ReorderSam \
	I=${RESULTS_DIR}/${RG_BAM} \
	O=${RESULTS_DIR}/${REORDER_BAM} \
	R=${REF_FASTA} \
	CREATE_INDEX=true \
	TMP_DIR=${TEMP_DIR}

REORDER_RET=$?


# If the mapping gave an error, exit with error
if [ $REORDER_RET -ne 0 ]
then
	exit 15
fi


# If there were no errors, remove input file
if [ ${CLEAN}=true ]
then
	rm ${RESULTS_DIR}/${RG_BAM}
	log "Removed ${RG_BAM}" 4
fi


