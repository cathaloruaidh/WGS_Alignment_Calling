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




### Print the recalibrated reads
# Run the GATK command


java ${JAVA_OPTIONS} -jar ${GATK_FILE} \
	-T PrintReads \
	-R ${REF_FASTA} \
	-I ${RESULTS_DIR}/${REALIGN_BAM} \
	-o ${RESULTS_DIR}/${BQSR_BAM} \
	-BQSR ${RESULTS_DIR}/${BQSR_TABLE_BEFORE} \
	-nct ${NPROCS} \
	-log ${LOG_DIR}/${OUTPUT_PREFIX}.ALIGN.${1}.log 


PR_RET=$?




# If the mapping gave an error, return, else cleanup
if [ $PR_RET -ne 0 ]
then
	exit 15
fi



# If there were no errors, remove input file
if [ "${CLEAN}" = true ]
then
	rm ${RESULTS_DIR}/${REALIGN_BAM}
	log "Removed ${REALIGN_BAM}" 4
fi
