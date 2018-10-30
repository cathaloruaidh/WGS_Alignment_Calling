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




### Sort the BAM file for ease of future processing
# Run the picard command
log "Sorting the BAM file" 3

java ${JAVA_OPTIONS} -jar ${PICARD_FILE} SortSam \
	I=${RESULTS_DIR}/${REORDER_BAM} \
	O=${RESULTS_DIR}/${SORT_BAM} \
	SORT_ORDER=coordinate \
	CREATE_INDEX=true \
	MAX_RECORDS_IN_RAM=1500000 \
	TMP_DIR=${TEMP_DIR} \
2> >( tee ${LOG_DIR}/${OUTPUT_PREFIX}.ALIGN.${1}.log >&2 )

SORT_RET=$?



# If the there were errors, exit with error
if [ $SORT_RET -ne 0 ]
then
	exit 15
fi


# If there were no errors, remove input file
if [ "${CLEAN}" = true ]
then
	rm ${RESULTS_DIR}/${REORDER_BAM}
	log "Removed ${REORDER_BAM}" 4
fi


