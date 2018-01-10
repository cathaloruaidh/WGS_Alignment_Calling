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


java ${JAVA_OPTIONS} -jar ${GATK_FILE} \
	-T AnalyzeCovariates\
	-R ${REF_FASTA} \
	-before ${RESULTS_DIR}/${BQSR_TABLE_BEFORE} \
	-after ${RESULTS_DIR}/${BQSR_TABLE_AFTER} \
	-plots ${GRAPHICS_DIR}/${BQSR_PLOTS} \
	-csv ${RESULTS_DIR}/${BQSR_CSV} \
	-log ${LOG_DIR}/$1.log 


AC_RET=$?




# If the mapping gave an error, return, else cleanup
if [ $AC_RET -ne 0 ]
then
	exit 15
fi

