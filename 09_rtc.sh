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




### Create targel intervals for realignment
# Run the GATK command


java ${JAVA_OPTIONS} -jar ${GATK_FILE} \
	-T RealignerTargetCreator \
	-nt ${NPROCS} \
	-R ${REF_FASTA} \
	--known ${INDELS} \
	-I ${RESULTS_DIR}/${NODUP_BAM} \
	-o ${RESULTS_DIR}/${REALIGN_INTERVALS} \
	-log ${LOG_DIR}/$1.log 



RTC_RET=$?




# If the creator gave an error, exit with errors
if [ $RTC_RET -ne 0 ]
then
	exit 15
fi

