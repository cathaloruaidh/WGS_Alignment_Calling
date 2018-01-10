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




### Second pass Recalibration of Base Quality Scores
# Run the picard command


java ${JAVA_OPTIONS} -jar ${GATK_FILE} \
	-T BaseRecalibrator \
	-nct ${NPROCS} \
	-R ${REF_FASTA} \
	-knownSites ${DBSNP} \
	-knownSites ${INDELS} \
	-BQSR  ${RESULTS_DIR}/${BQSR_TABLE_BEFORE} \
	-I ${RESULTS_DIR}/${REALIGN_BAM} \
	-o ${RESULTS_DIR}/${BQSR_TABLE_AFTER} \
	-log ${LOG_DIR}/$1.log \
	--sort_by_all_columns 


BR_RET=$?




# If the recalibration gave an error, exit with error
if [ $BR_RET -ne 0 ]
then
	exit 15
fi

