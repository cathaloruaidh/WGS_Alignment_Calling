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




### Mark duplicate reads, save metrics 
# Run the picard command


java ${JAVA_OPTIONS} -jar ${PICARD_FILE} MarkDuplicates \
	I=${RESULTS_DIR}/${SORT_BAM} \
	O=${RESULTS_DIR}/${NODUP_BAM} \
	M=${RESULTS_DIR}/${DUP_MET} \
	AS=true \
	CREATE_INDEX=true \
	TMP_DIR=${TEMP_DIR} \
2> >( tee ${LOG_DIR}/${OUTPUT_PREFIX}.ALIGN.${1}.log >&2 )


MD_RET=$?



# If there were errors, exit with error
if [ $MD_RET -ne 0 ] 
then
	exit 15
fi


# If there were no errors, remove input file
if [ "${CLEAN}" = true ]
then
	rm ${RESULTS_DIR}/${SORT_BAM}
	log "Removed ${SORT_BAM}" 4
fi


