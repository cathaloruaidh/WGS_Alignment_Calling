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




### Call the variants with HaplotypeCaller
# Run the GATK command


java ${JAVA_OPTIONS} -jar ${GATK_FILE} -T HaplotypeCaller \
	-R ${REF_FASTA} \
	-I ${RESULTS_DIR}/${BQSR_BAM} \
	-o ${RESULTS_DIR}/${GVCF} \
	-ERC GVCF \
	--dbsnp ${DBSNP} \
	--annotation MappingQualityZero \
	--annotation VariantType \
	--annotation AlleleBalance \
	--annotation AlleleBalanceBySample \
	--excludeAnnotation ChromosomeCounts \
	--excludeAnnotation FisherStrand \
	--excludeAnnotation StrandOddsRatio \
	--excludeAnnotation QualByDepth \
	--GVCFGQBands 10 \
	--GVCFGQBands 20 \
	--GVCFGQBands 30 \
	--GVCFGQBands 40 \
	--GVCFGQBands 60 \
	--GVCFGQBands 80 \
	--standard_min_confidence_threshold_for_calling 0 \
	-nct 4 \
	-log ${LOG_DIR}/${OUTPUT_PREFIX}.ALIGN.${1}.log 
	
HC_RET=$?


bgzip -f ${RESULTS_DIR}/${GVCF}

BGZ_RET=$?


tabix -f ${RESULTS_DIR}/${GVCF_GZ}

TBX_RET=$?



# If the mapping gave an error, return, else cleanup
if [ $HC_RET -ne 0 ] 
then
	exit 15
elif [ $BGZ_RET -ne 0 ]
then
	exit 15
elif [ $TBX_RET -ne 0 ]
then
	exit 15
fi

