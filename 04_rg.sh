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




### Replace the read group for all reads 
# Run the picard command


if [ -z "${READ_GROUP}" ]
then
	cp ${RESULTS_DIR}/${BAM} ${RESULTS_DIR}/${RG_BAM}
else
	java ${JAVA_OPTIONS} -jar ${PICARD_FILE} AddOrReplaceReadGroups \
		I=${RESULTS_DIR}/${BAM} \
		O=${RESULTS_DIR}/${RG_BAM} \
		RGID=${SOURCE_FILE} \
		RGLB=lib1 \
		RGPL=illumina \
		RGPU=${SOURCE_FILE} \
		RGSM=${SOURCE_FILE} \
		CREATE_INDEX=true \
		TMP_DIR=${TEMP_DIR}
fi
RG_RET=$?


# If the read replacement gave an error, exit with an error
if [ $RG_RET -ne 0 ]
then
	exit 15
fi


# If there were no errors, remove input file
if [ ${CLEAN}=true ]
then
	rm ${RESULTS_DIR}/${BAM}
	log "Removed ${BAM}" 4
fi

