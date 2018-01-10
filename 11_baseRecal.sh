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




### Recalibrate Base Quality Scores
# Run the GATK command


java ${JAVA_OPTIONS} -jar ${GATK_FILE} \
	-T BaseRecalibrator \
	-nct ${NPROCS} \
	-R ${REF_FASTA} \
	-knownSites ${DBSNP} \
	-knownSites ${INDELS} \
	-I ${RESULTS_DIR}/${REALIGN_BAM} \
	-o ${RESULTS_DIR}/${BQSR_TABLE_BEFORE} \
	-log ${LOG_DIR}/$1.log \
	--sort_by_all_columns 



BR_RET=$?




# If the recalibration gave an error, exit with error
if [ $BR_RET -ne 0 ]
then
	exit 15
fi

