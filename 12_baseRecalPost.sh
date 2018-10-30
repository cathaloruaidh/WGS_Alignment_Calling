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
	-R ${REF_FASTA} \
	-I ${RESULTS_DIR}/${REALIGN_BAM} \
	-o ${RESULTS_DIR}/${BQSR_TABLE_AFTER} \
	-knownSites ${DBSNP} \
	-knownSites ${INDELS} \
	-BQSR  ${RESULTS_DIR}/${BQSR_TABLE_BEFORE} \
	--sort_by_all_columns  \
	-nct ${NPROCS} \
	-log ${LOG_DIR}/${OUTPUT_PREFIX}.ALIGN.${1}.log


BR_RET=$?




# If the recalibration gave an error, exit with error
if [ $BR_RET -ne 0 ]
then
	exit 15
fi

