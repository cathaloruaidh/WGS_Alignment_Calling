#!/bin/bash

############################################################
#
# Assembly of NGS data from FASTQ to GVCF 
# Cathal Ormond 2017. 
#
# Alignment of reads from FASTQ file to reference genome
# Conversion to BAM file
#
# Based heavily on scripts found here:
# https://github.com/genepi-freiburg/gwas
#
############################################################




### Validate the final BAM file before calling variants
# Run the picard command


log "Validating BAM file:" 3
java ${JAVA_OPTIONS} -jar ${PICARD_FILE} ValidateSamFile \
	I=${RESULTS_DIR}/${BQSR_BAM} \
	O=${RESULTS_DIR}/${FINAL_VAL} \
	MODE=SUMMARY \
	MAX_OUTPUT=null \
	TMP_DIR=${TEMP_DIR}

VAL_RET=$?

log "$(cat ${RESULTS_DIR}/${FINAL_VAL})" 3 
log "" 3



log "Determining samtools statistics" 3
samtools stats -@ ${APROCS} ${RESULTS_DIR}/${BQSR_BAM} > ${RESULTS_DIR}/${BQSR_STATS}

S_RET=$?



log "Plotting graphs" 3
plot-bamstats -p ${GRAPHICS_DIR}/${FINAL_PREFIX} ${RESULTS_DIR}/${BQSR_STATS}

B_RET=$?

rm ${GRAPHICS_DIR}/${SOURCE_FILE}*.gp


# If the mapping gave an error, return, else cleanup
if [ $VAL_RET -ne 0 ] 
then
	exit 15
elif [ $S_RET -ne 0 ]
then
	exit 15
elif [ $B_RET -ne 0 ]
then
	exit 15
fi

