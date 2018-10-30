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




### Align the reads to the reference genome, and convert to a BAM
# Run the BWA and samtools commands

if [[ ${ALT} = false ]]
then
	bwa mem \
		-R "@RG\tID:${OUTPUT_PREFIX##*/}\tSM:${OUTPUT_PREFIX##*/}\tPL:unknown\tLB:${OUTPUT_PREFIX##*/}" \
		-t ${NPROCS} \
		-c 250 \
		-M \
		-v 1 ${REF_FASTA} ${READ1} ${READ2} \
		| samtools view -Sb -h - > ${RESULTS_DIR}/${BAM} \
		2> >( tee ${LOG_DIR}/${OUTPUT_PREFIX}.ALIGN.${1}.log >&2 )
else
	bwa mem \
		-R "@RG\tID:${OUTPUT_PREFIX##*/}\tSM:${OUTPUT_PREFIX##*/}\tPL:unknown\tLB:${OUTPUT_PREFIX##*/}" \
		-t ${NPROCS} \
		-c 250 \
		-M \
		-v 1 ${REF_FASTA} ${READ1} ${READ2} | samblaster -M --addMateTags | samtools view -Sb -h - > ${RESULTS_DIR}/${BAM} \
		2> >( tee ${LOG_DIR}/${OUTPUT_PREFIX}.ALIGN.${1}.log >&2 )
fi

MAP_RET=$?



# If the alignment gave an error, exit with an error
if [ $MAP_RET -ne 0 ]
then
	exit 15
fi



