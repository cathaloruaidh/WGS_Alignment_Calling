#!/bin/bash

############################################################
#
# Assembly of NGS data from FASTQ to GVCF 
# Cathal Ormond 2017. 
#
# Initial set up and creation of parameters. 
#
# Based heavily on scripts found here:
# https://github.com/genepi-freiburg/gwas
#
############################################################






### Text variables
PASS_TEST_LIGHT="[\e[102mPASSED\e[0m]"
PASS_TEST="[\e[42mPASSED\e[0m]"
FAIL_TEST_LIGHT="[\e[101mFAILED\e[0m]"
FAIL_TEST="[\e[41mFAILED\e[0m]"




# Create the main log file
if [ -f ${MAIN_LOG_FILE} ]
then
	mv ${MAIN_LOG_FILE} ${MAIN_LOG_FILE}.$(date +%Y-%m-%d_%H.%M.%S)
	touch ${MAIN_LOG_FILE}
	log "Renaming previous log file" 3
else
	log "Creating the main log file: ${MAIN_LOG_FILE}" 3
	touch ${MAIN_LOG_FILE}
fi




### Source name
# The base name of the raw data files.
SOURCE_FILE=$1


if [[ -f ${SOURCE_DIR}/${SOURCE_FILE}_R1.fastq ]]
then
	READ1=${SOURCE_DIR}/${SOURCE_FILE}_R1.fastq
	READ2=${SOURCE_DIR}/${SOURCE_FILE}_R2.fastq

elif [[ -f ${SOURCE_DIR}/${SOURCE_FILE}_R1.fq ]]
then
	READ1=${SOURCE_DIR}/${SOURCE_FILE}_R1.fq
	READ2=${SOURCE_DIR}/${SOURCE_FILE}_R2.fq

elif [[ -f ${SOURCE_DIR}/${SOURCE_FILE}_R1.fastq.gz ]]
then
	READ1=${SOURCE_DIR}/${SOURCE_FILE}_R1.fastq.gz
	READ2=${SOURCE_DIR}/${SOURCE_FILE}_R2.fastq.gz

elif [[ -f ${SOURCE_DIR}/${SOURCE_FILE}_R1.fq.gz ]]
then
	READ1=${SOURCE_DIR}/${SOURCE_FILE}_R1.fq.gz
	READ2=${SOURCE_DIR}/${SOURCE_FILE}_R2.fq.gz

elif [[ -f ${SOURCE_DIR}/${SOURCE_FILE}.R1.fastq ]]
then
	READ1=${SOURCE_DIR}/${SOURCE_FILE}.R1.fastq
	READ2=${SOURCE_DIR}/${SOURCE_FILE}.R2.fastq

elif [[ -f ${SOURCE_DIR}/${SOURCE_FILE}.R1.fq ]]
then
	READ1=${SOURCE_DIR}/${SOURCE_FILE}.R1.fq
	READ2=${SOURCE_DIR}/${SOURCE_FILE}.R2.fq

elif [[ -f ${SOURCE_DIR}/${SOURCE_FILE}.R1.fastq.gz ]]
then
	READ1=${SOURCE_DIR}/${SOURCE_FILE}.R1.fastq.gz
	READ2=${SOURCE_DIR}/${SOURCE_FILE}.R2.fastq.gz

elif [[ -f ${SOURCE_DIR}/${SOURCE_FILE}.R1.fq.gz ]]
then
	READ1=${SOURCE_DIR}/${SOURCE_FILE}.R1.fq.gz
	READ2=${SOURCE_DIR}/${SOURCE_FILE}.R2.fq.gz
else
	log "Cannot find read files of the format '${SOURCE_FILE}_R1.fastq' etc." 1
	exit 1
fi


log "Found FASTQ files with prefix: ${SOURCE_FILE}" 3
log " " 3








### Processors and Memory
TPROCS=$(grep -c ^processor /proc/cpuinfo)
#TPROCS=14

#if [[ ${TPROCS} -gt 4 ]]
#then
#	NPROCS=$(( ${TPROCS} - 4 ))
#else
#	NPROCS=1
#fi

if [ -z "${NPROCS}" ] 
then
	NPROCS=4
fi

APROCS=$(( ${NPROCS} - 1 ))


log "Using ${NPROCS} processors out of a total ${TPROCS}" 3
log " " 3


# Max Memory used by one process
# set to > 1/5 of Vishnu's max
JAVA_TEMP="-Djava.io.temp=${TEMP_DIR}"
JAVA_OPTIONS=" -Xmx${JAVA_MAX} -Xms${JAVA_MIN} ${JAVA_TEMP}"




### Global Directories and Files
# Test if the source directory exists
if [ ! -d ${SOURCE_DIR} ]
then
	log "Problem with source directory: ${SOURCE_DIR}" 1
	exit 8
fi

log  "Currently directory: ${SOURCE_DIR}" 4

log " " 4




### Create required files and directories
# Log directory for all log files generated by Plink
if [ ! -d ${LOG_DIR} ]
then
	mkdir -p ${LOG_DIR}
	log "Creating log directory: ${LOG_DIR}" 3

else
	log "Log directory already exists at: ${LOG_DIR#${SOURCE_DIR}/}" 4
fi



# Results directory for all results files
if [ ! -d ${RESULTS_DIR} ]
then
	log "Creating results directory: ${RESULTS_DIR}" 3
	mkdir -p ${RESULTS_DIR}

else
	log "Results directory already exists at: ${RESULTS_DIR#${SOURCE_DIR}/}" 4 # - deleting contents" 3
#	rm -f ${RESULTS_DIR}/* 2> /dev/null
fi



# Temporary directory for any intermediate steps
if [ ! -d ${TEMP_DIR} ]
then
	log "Creating temp directory: ${TEMP_DIR#${SOURCE_DIR}/}" 3
	mkdir -p ${TEMP_DIR}

else
	log "Temp directory already exists at: ${TEMP_DIR#${SOURCE_DIR}/} - deleting contents" 4
	rm -f ${TEMP_DIR}/* 2> /dev/null
fi



# Graphics directory for all images for further analysis
if [ ! -d ${GRAPHICS_DIR} ]
then
	log "Creating graphics directory: ${GRAPHICS_DIR}" 3
	mkdir -p ${GRAPHICS_DIR}

else
	log "Graphics directory already exists at: ${GRAPHICS_DIR#${SOURCE_DIR}/} - deleting contents" 4
	rm -f ${GRAPHICS_DIR}/* 2> /dev/null
fi



# Error directory for any output errors
if [ ! -d ${ERRORS_DIR} ]
then
	log "Creating error directory: ${ERRORS_DIR#${SOURCE_DIR}/}" 3
	mkdir -p ${ERRORS_DIR}

else
	log "Error directory already exists at: ${ERRORS_DIR#${SOURCE_DIR}/} - deleting contents" 4
	rm -f ${ERRORS_DIR}/* 2> /dev/null
fi


log " " 4



# Create summary file for results
if [ -f ${SUMMARY_FILE} ]
then
	log "Renaming previous summary file" 3
	mv ${SUMMARY_FILE} ${SUMMARY_FILE}.$(date +%Y-%m-%d_%H.%M.%S)
	touch ${SUMMARY_FILE}
else
	log "Creating the summary file: ${SUMMARY_FILE}" 3
	touch ${SUMMARY_FILE}
fi

echo "Data Summary File for Quality Control" >> ${SUMMARY_FILE}
date >> ${SUMMARY_FILE}
echo -e "\n\n" >> ${SUMMARY_FILE}


log " " 3




### Set the program paths
PICARD_FILE=${TOOL_DIR}/picard.jar

GATK34_FILE=${TOOL_DIR}/gatk/GenomeAnalysisTK_3.4.jar
GATK37_FILE=${TOOL_DIR}/gatk/GenomeAnalysisTK_3.7.jar
GATK38_FILE=${TOOL_DIR}/gatk/GenomeAnalysisTK_3.8.jar



# if the variables are empty, throw an error
if [ ! -x $(command -v plink) ]
then
	log "Error: plink not found." 1
	exit 6
fi
log "Plink was successfully found." 4



if [ ! -x $(command -v Rscript) ]
then
	log "Error: Rscript not found" 1
	exit 7
fi
log "R was sucessfully found." 4



if [ ! -x $(command -v bwa) ]
then
	log "Error: bwa not found." 1
	exit 6
fi
log "bwa was successfully found." 4



if [ ! -x $(command -v samtools) ]
then
	log "Error: samtools not found." 1
	exit 6
fi
log "samtools was successfully found." 4



if [ ! -f ${PICARD_FILE} ]
then
	log "Error: picard not found." 1
	exit 6
fi
log "Picard was successfully found." 4



if [ ! -f ${GATK34_FILE} ] && [ ! -f ${GATK37_FILE} ] && [ ! -f ${GATK38_FILE} ]
then
	log "Error: GATK 3.4, 3.7 and 3.8 not found." 1
	exit 6
fi
log "GATK was successfully found." 4



# Edinburgh pipeline uses GATK 3.4, so start with that
# and use newer versions until one is found. 

if [ ! -f ${GATK_FILE} ]
then
	GATK_FILE=${GATK34_FILE}
fi


if [ ! -f ${GATK_FILE} ]
then
	GATK_FILE=${GATK37_FILE}
fi


if [ ! -f ${GATK_FILE} ]
then
	GATK_FILE=${GATK38_FILE}
fi




### Find the Resource Files
INDELS=${REF_DIR}/GRCh38/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz
THOUSANDG=${REF_DIR}/GRCh38/1000G_phase1.snps.high_confidence.hg38.vcf.gz
OMNI=${REF_DIR}/GRCh38/1000G_omni2.5.hg38.vcf.gz
HAPMAP=${REF_DIR}/GRCh38/hapmap_3.3.hg38.vcf.gz


log " " 4

if [[ ! -f ${REF_FASTA} ]]
then
	GRCH38=${REF_DIR}/GRCh38/GRCh38_full_analysis_set_plus_decoy_hla.fa
	log "Specified reference file (${REF_FASTQ}) does not exist, using $(basename ${GRCH38})" 2
	REF_FASTA=${GRCH38}
else
	log "Reference file: $(basename ${REF_FASTA})" 4
fi


if [[ ! -f ${DBSNP} ]]
then
	DBSNP150=${REF_DIR}/GRCh38/dbsnp_150.hg38.vcf.gz
	DBSNP146=${REF_DIR}/GRCh38/dbsnp_146.hg38.vcf.gz

	log "Specified dbSNP file (${DBSNP}) does not exist, using $(basename ${DBSNP150})" 2
	DBSNP=${DBSNP150}
else
	log "dbSNP file: $(basename ${DBSNP})" 4
fi



if [[ ! -f ${INDELS} ]]
then
	log "The indel file does not exist at ${INDELS}" 1
	exit 1
fi

log "Indel reference file: $(basename ${INDELS})" 4


if [[ ! -f ${THOUSANDG} ]]
then
	log "The 1000G reference VCF file does not exist at ${THOUSANDG}" 1
	exit 1
fi

log "1000G VCF reference file: $(basename ${THOUSANDG})" 4


if [[ ! -f ${OMNI} ]]
then
	log "The Omni reference VCF file does not exist at ${OMNI}" 1
	exit 1
fi

log "Omni reference file: $(basename ${OMNI})" 4


if [[ ! -f ${HAPMAP} ]]
then
	log "The HapMap reference VCF file does not exist at ${HAPMAP}" 1
	exit 1
fi

log "HapMap reference file: $(basename ${HAPMAP})" 4

log " "  4






### Name the output files

BAM=${SOURCE_FILE}.bam
RG_BAM=${SOURCE_FILE}.rg.bam
REORDER_BAM=${SOURCE_FILE}.rg.reorder.bam

SORT_BAM=${SOURCE_FILE}.rg.reorder.sort.bam
SORT_BAI=${SOURCE_FILE}.rg.reorder.sort.bai
FIRST_VAL=${SOURCE_FILE}.rg.reorder.sort.bam.validation.txt

DUP_MET=${SOURCE_FILE}.rg.reorder.sort.metrics
NODUP_BAM=${SOURCE_FILE}.rg.reorder.sort.nodup.bam
NODUP_BAI=${SOURCE_FILE}.rg.reorder.sort.nodup.bai

REALIGN_INTERVALS=${SOURCE_FILE}.rg.reorder.sort.nodup.realign.intervals
REALIGN_BAM=${SOURCE_FILE}.rg.reorder.sort.nodup.realign.bam

BQSR_TABLE_BEFORE=${SOURCE_FILE}.rg.reorder.sort.nodup.realign.bqsr.before.table
BQSR_TABLE_AFTER=${SOURCE_FILE}.rg.reorder.sort.nodup.realign.bqsr.after.table
BQSR_PLOTS=${SOURCE_FILE}.rg.reorder.sort.nodup.realign.bqsr.plots.pdf
BQSR_CSV=${SOURCE_FILE}.rg.reorder.sort.nodup.realign.bqsr.csv
BQSR_BAM=${SOURCE_FILE}.rg.reorder.sort.nodup.realign.bqsr.bam

FINAL_VAL=${SOURCE_FILE}.rg.reorder.sort.nodup.realign.bqsr.validation.txt
BQSR_STATS=${SOURCE_FILE}.rg.reorder.sort.nodup.realign.bqsr.stats
BQSR_WGS=${SOURCE_FILE}.rg.reorder.sort.nodup.realign.bqsr.wgs.txt
FINAL_PREFIX=${SOURCE_FILE}.final


GVCF=${SOURCE_FILE}.g.vcf
GVCF_GZ=${SOURCE_FILE}.g.vcf.gz
GVCF_TBI=${SOURCE_FILE}.g.vcf.gz.tbi

