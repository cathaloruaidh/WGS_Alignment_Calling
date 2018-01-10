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




### Realign locally around indels
# Run the GATK command


java ${JAVA_OPTIONS} -jar ${GATK_FILE} \
	-T IndelRealigner \
	-R ${REF_FASTA} \
	-known ${INDELS} \
	-I ${RESULTS_DIR}/${NODUP_BAM} \
	-o ${RESULTS_DIR}/${REALIGN_BAM} \
	-log ${LOG_DIR}/$1.log \
	-targetIntervals ${RESULTS_DIR}/${REALIGN_INTERVALS} \
	--LODThresholdForCleaning 5.0 \
	--consensusDeterminationModel USE_READS \
	--entropyThreshold 0.15 \
	--maxReadsInMemory 150000 \
	--maxIsizeForMovement 3000 \
	--maxPositionalMoveAllowed 200 \
	--maxConsensuses 30 \
	--maxReadsForConsensuses 120 \
	--maxReadsForRealignment 20000 


IR_RET=$?




# If the realignment gave an error, exit with error
if [ $IR_RET -ne 0 ]
then
	exit 15
fi



# If there were no errors, remove input file
if [ ${CLEAN}=true ]
then
	rm ${RESULTS_DIR}/${NODUP_BAM}
	log "Removed ${NODUP_BAM}" 4
fi
