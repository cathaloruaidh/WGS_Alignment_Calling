#!/bin/bash

############################################################
#
# Assembly of CURR_SCRIPT data from FASTQ to GVCF 
# Cathal Ormond 2017. 
#
# 
# 
# 
# usage: ./main.sh -f BASE [-i] [-g]
#
# -f BASE
#     BASE is the base file name for the GWAS files
# -i
#    Run interactively, i.e. confirm plink values at each 
#    step of the analysis
# -g
#	Create graphics
#
############################################################




### Global directories and files
# The raw data lies here. 
# BED or PED/MAP files must live here. 
SOURCE_DIR=${PWD}

LOG_DIR=${SOURCE_DIR}/logs
RESULTS_DIR=${SOURCE_DIR}/results
TEMP_DIR=${SOURCE_DIR}/temp
GRAPHICS_DIR=${SOURCE_DIR}/graphics

MAIN_LOG_FILE=${LOG_DIR}/main.log


# Edit these 4 files. 
SCRIPTS_DIR=/home/shared/scripts
CURR_SCRIPT_DIR=${SCRIPTS_DIR}/ngs-variant-calling
TOOL_DIR=/home/shared/tools
REF_DIR=/home/shared/reference/ReferenceGenome
REFERENCE=GRCh38


# Get functions defined elsewhere
. ${SCRIPTS_DIR}/func.sh

if [ $? -ne 0 ]
then
	log "Functions script returned an error: $?" 1
	exit 11
fi



set -o pipefail
ulimit -n $(ulimit -Hn) 2> /dev/null


### Argument processing
ALT=false
CLEAN=false
DNSNP=""
GATK_FILE=${TOOL_DIR}/gatk/GenomeAnalysisTK_3.4.jar
E=100
F=0
INDELS=""
JAVA_MAX="6G"
JAVA_MIN="6G"
OUTPUT_PREFIX="output_file"
S=0
NPROCS=4  # change to appropriate default
VERBOSE=3


cmd(){
	echo `basename $0`
}


usage(){
echo -e "\
Usage: `cmd` [OPTIONS ...] \n

-a, --alt; ; Run alternate pipeline (mark duplicates); [${ALT}]
-b, --build ; hg19,hg38 ; Genome build; [hg38]
-c, --clean; ; Remove all input files once finished; [${CLEAN}] 
-d, --dbsnp; <FILE>; dbSNP VCF file; [v 150]
-e, --end; <INT>; Tool to finish on; [${E}]
-f, --file; <FILE>; Name of source file. Looks for inputs of the
; ; form <FILE>_R1.fq.gz or similar; [${SOURCE_FILE}]
-g, --gatk; <FILE>; GATK file; [GATK 3.4]
-h, --help; ; Output this message
-i, --indels; <FILE> ; Indels VCF file ; [Mills_and_1000G]
-m, --mem-min; <INT>; Java minimum memory; [${JAVA_MIN}]
-o, --output; <FILE>; Output file prefix; [${OUTPUT_PREFIX}]
-r, --reference; <FILE>; FASTA Reference file; [GRCh38_full]
-s, --start; <INT>; Tool to start on; [${S}]
-t, --threads; <INT>; Number of threads for multithreaded processes; [${NPROCS}]
-v, --verbose; <INT>; Set verbosity level; [${VERBOSE}]
-x, --mem-max; <INT>; Java maximum memory; [${JAVA_MAX}]
" | column -t -s ";"
}


OPTS=`getopt -o ab:cd:e:f:g:hi:m:o:r:s:t:v:x: \
	--long alt,file:,start:,end:,threads:,help,verbose:,dbsnp:,reference:,mem-min:,mem-max:,clean,gatk:,output:,build:,indels: \
	-n '$(cmd)' -- "$@"`

if [ $? != 0 ]
then 
	echo "Error with arguments. Terminating ..." >&2
	exit 1
fi

# Note the quotes around `$TEMP': they are essential!
eval set -- "$OPTS"



while true; do
	case "$1" in
		-a | --alt)
			ALT=true
			shift
			;;

		-b | --build)
			BUILD="$2"
			shift 2
			;;

		-c | --clean)
			CLEAN=true
			shift
			;;

		-d | --dbsnp)
			DBSNP="$2"
			shift 2
			;;

		-e | --end)
			E="$2"
			shift 2
			;;

		-f | --file)
			SOURCE_FILE="$2"
			shift 2
			;;

		-g | --gatk)
			GATK_FILE="$2"
			shift 2
			;;

		-h | --help)
			usage
			exit 0
			;;

		-i | --indels)
			INDELS="$2"
			shift 2
			;;

		-m | --mem-min)
			JAVA_MIN=$2
			shift 2
			;;

		-o | --output)
			OUTPUT_PREFIX="$2"
			shift 2
			;;

		-r | --reference)
			REF_FASTA="$2"
			shift 2
			;;

		-s | --start)
			S="$2"
			shift 2
			;;

		-t | --threads)
			NPROCS="$2"
			shift 2
			;;

		-v | --verbose)
			VERBOSE="$2"
			shift 2
			;;

		-x | --mem-max)
			JAVA_MAX=$2
			shift 2
			;;

		--)
			shift
			break
			;;

		\?)
			log "Invalid flags. Exiting ... " 1
			exit 12
			break
			;;

		:)
			log "Flag requires an argument. Exiting ... " 1
			exit 13
			break
			;;

		*)
			log "Error with flags. Exiting ... " 1
			exit 14
			break
			;;
	esac
done




### Text variables
PASS_TEST_LIGHT="[\e[102mPASSED\e[0m]"
PASS_TEST="[\e[42mPASSED\e[0m]"
FAIL_TEST_LIGHT="[\e[101mFAILED\e[0m]"
FAIL_TEST="[\e[41mFAILED\e[0m]"




# Max Memory used by one process
# set to > 1/5 of Vishnu's max
JAVA_TEMP="-Djava.io.tmpdir=${TEMP_DIR}"
JAVA_OPTIONS=" -Xms${JAVA_MIN} -Xmx${JAVA_MAX} ${JAVA_TEMP}"
### Set the program paths



PICARD_FILE=${TOOL_DIR}/picard.jar

GATK34_FILE=${TOOL_DIR}/gatk/GenomeAnalysisTK_3.4.jar
GATK37_FILE=${TOOL_DIR}/gatk/GenomeAnalysisTK_3.7.jar
GATK38_FILE=${TOOL_DIR}/gatk/GenomeAnalysisTK_3.8.jar



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




### Find the Resource Files, depending on the reference build.
if [[ $( echo ${BUILD} | grep -E "19" ) ]]
then
	REFERENCE=hg19
	REF_FILE=${REF_DIR}/${REFERENCE}/ucsc.hg19.fasta
	INDELS_FILE=${REF_DIR}/${REFERENCE}/Mills_and_1000G_gold_standard.indels.hg19.sites.vcf.gz
	DBSNP_NEW=${REF_DIR}/${REFERENCE}/dbsnp_150.hg19.vcf.gz
	DBSNP_OLD=${REF_DIR}/${REFERENCE}/dbsnp_138.hg19.vcf.gz

else
	REFERENCE=GRCh38
	REF_FILE=${REF_DIR}/${REFERENCE}/GRCh38_full_analysis_set_plus_decoy_hla.fa
	INDELS_FILE=${REF_DIR}/${REFERENCE}/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz
	DBSNP_NEW=${REF_DIR}/${REFERENCE}/dbsnp_150.hg38.vcf.gz
	DBSNP_OLD=${REF_DIR}/${REFERENCE}/dbsnp_146.hg38.vcf.gz
fi



if [[ ! -f ${REF_FASTA} ]]
then
	if [[ -z ${REF_FASTA} ]]
	then
		log "No referece file specified, using ${REF_FILE##*/}" 4
	else
		log "Specified reference file (${REF_FASTA}) does not exist, using ${REF_FILE##*/}" 2
	fi

	REF_FASTA=${REF_FILE}
else
	log "Reference file: $(basename ${REF_FASTA})" 4
fi


if [[ ! -f ${DBSNP} ]]
then
	if [[ -z ${DBSNP} ]]
	then
		log "No dbSNP file specified, using ${DBSNP_NEW##*/}" 4
	else
		log "Specified dbSNP file (${DBSNP}) does not exist, using $(basename ${DBSNP_NEW##*/})" 2
	fi
	DBSNP=${DBSNP_NEW}
else
	log "dbSNP file: $(basename ${DBSNP})" 4
fi


if [[ ! -f ${INDELS} ]]
then
	if [[ -z ${INDELS} ]]
	then
		log "No indel file specified, using ${INDELS_FILE##*/}" 4
	else
		log "Specified dbSNP file (${INDELS}) does not exist, using $(basename ${INDELS_FILE##*/})" 2
	fi
	INDELS=${INDELS_FILE}
fi

log " "  4







### Name the output files

BAM=${OUTPUT_PREFIX}.bam
RG_BAM=${OUTPUT_PREFIX}.rg.bam
REORDER_BAM=${OUTPUT_PREFIX}.rg.reorder.bam

SORT_BAM=${OUTPUT_PREFIX}.rg.reorder.sort.bam
SORT_BAI=${OUTPUT_PREFIX}.rg.reorder.sort.bai
FIRST_VAL=${OUTPUT_PREFIX}.rg.reorder.sort.validation.txt

DUP_MET=${OUTPUT_PREFIX}.rg.reorder.sort.metrics
NODUP_BAM=${OUTPUT_PREFIX}.rg.reorder.sort.nodup.bam
NODUP_BAI=${OUTPUT_PREFIX}.rg.reorder.sort.nodup.bai

REALIGN_INTERVALS=${OUTPUT_PREFIX}.rg.reorder.sort.nodup.realign.intervals
REALIGN_BAM=${OUTPUT_PREFIX}.rg.reorder.sort.nodup.realign.bam

BQSR_TABLE_BEFORE=${OUTPUT_PREFIX}.rg.reorder.sort.nodup.realign.bqsr.before.table
BQSR_TABLE_AFTER=${OUTPUT_PREFIX}.rg.reorder.sort.nodup.realign.bqsr.after.table
BQSR_PLOTS=${OUTPUT_PREFIX}.rg.reorder.sort.nodup.realign.bqsr.plots.pdf
BQSR_CSV=${OUTPUT_PREFIX}.rg.reorder.sort.nodup.realign.bqsr.csv
BQSR_BAM=${OUTPUT_PREFIX}.rg.reorder.sort.nodup.realign.bqsr.bam

FINAL_VAL=${OUTPUT_PREFIX}.rg.reorder.sort.nodup.realign.bqsr.validation.txt
BQSR_STATS=${OUTPUT_PREFIX}.rg.reorder.sort.nodup.realign.bqsr.stats
BQSR_WGS=${OUTPUT_PREFIX}.rg.reorder.sort.nodup.realign.bqsr.wgs.txt

GVCF=${OUTPUT_PREFIX}.g.vcf
GVCF_GZ=${OUTPUT_PREFIX}.g.vcf.gz
GVCF_TBI=${OUTPUT_PREFIX}.g.vcf.gz.tbi

REPORT_TEX=${OUTPUT_PREFIX}.report.tex



### Main section of pipeline
log $(printf '#%.0s' $(seq 1 $(($(tput cols)-35)) ) ) 3 2> /dev/null
log " " 3 2>/dev/null
log "Main pipeline section" 3
log " " 3
log "Pre-processing" 3
log " " 3

CURR=0


# Index the reference FASTA File 
CURR=$(( CURR + 1 ))
if [[ ${S} -le ${CURR} && ${E} -ge ${CURR} ]]
then
	NAME="01_index"
	log $NAME 3
	(. ${CURR_SCRIPT_DIR}/$NAME.sh $NAME) 
	testResult $? $NAME
fi



# Create the reference dictionary for the reference FASTA file
CURR=$(( CURR + 1 ))
if [[ ${S} -le ${CURR} && ${E} -ge ${CURR} ]]
then
	NAME="02_dict"
	log $NAME 3
	(. ${CURR_SCRIPT_DIR}/$NAME.sh $NAME) 
	testResult $? $NAME
fi



# Map the reads and convert to a BAM file
CURR=$(( CURR + 1 ))
if [[ ${S} -le ${CURR} && ${E} -ge ${CURR} ]]
then
	NAME="03_align"
	log $NAME 3
	(. ${CURR_SCRIPT_DIR}/$NAME.sh $NAME) 
	testResult $? $NAME
fi



# Edit the Read Group
CURR=$(( CURR + 1 ))
if [[ ${S} -le ${CURR} && ${E} -ge ${CURR} ]]
then
	NAME="04_rg"
	log $NAME 3
	(. ${CURR_SCRIPT_DIR}/$NAME.sh $NAME) 
	testResult $? $NAME
fi



# Reorder the BAM file
CURR=$(( CURR + 1 ))
if [[ ${S} -le ${CURR} && ${E} -ge ${CURR} ]]
then
	NAME="05_reorder"
	log $NAME 3
	(. ${CURR_SCRIPT_DIR}/$NAME.sh $NAME) 
	testResult $? $NAME
fi



# Sort the BAM file
CURR=$(( CURR + 1 ))
if [[ ${S} -le ${CURR} && ${E} -ge ${CURR} ]]
then
	NAME="06_sort"
	log $NAME 3
	(. ${CURR_SCRIPT_DIR}/$NAME.sh $NAME) 
	testResult $? $NAME
fi



# Validate the BAM file
CURR=$(( CURR + 1 ))
if [[ ${S} -le ${CURR} && ${E} -ge ${CURR} ]]
then
	NAME="07_validate"
	log $NAME 3
	(. ${CURR_SCRIPT_DIR}/$NAME.sh $NAME) 
	testResult $? $NAME
fi



# Mark all Duplicate reads
CURR=$(( CURR + 1 ))
if [[ ${S} -le ${CURR} && ${E} -ge ${CURR} ]]
then
	NAME="08_markDup"
	log $NAME 3
	
	if [ ${ALT} = true ]
	then 
		log "Skipping MarkDuplicates for ALT Pipeline." 3
		cp ${RESULTS_DIR}/${SORT_BAM} ${RESULTS_DIR}/${NODUP_BAM}
		log "Creating index file" 3
		samtools index -@ ${APROCS} ${RESULTS_DIR}/${NODUP_BAM} 
	else
		(. ${CURR_SCRIPT_DIR}/$NAME.sh $NAME) 
	fi

	testResult $? $NAME
fi



# Search for intervals to be realigned
CURR=$(( CURR + 1 ))
if [[ ${S} -le ${CURR} && ${E} -ge ${CURR} ]]
then
	NAME="09_rtc"
	log $NAME 3
	(. ${CURR_SCRIPT_DIR}/$NAME.sh $NAME) 
	testResult $? $NAME
fi




# Perform Realignment
CURR=$(( CURR + 1 ))
if [[ ${S} -le ${CURR} && ${E} -ge ${CURR} ]]
then
	NAME="10_indelRealign"
	log $NAME 3
	(. ${CURR_SCRIPT_DIR}/$NAME.sh $NAME) 
	testResult $? $NAME
fi



# Create recalibration table for BQSR
CURR=$(( CURR + 1 ))
if [[ ${S} -le ${CURR} && ${E} -ge ${CURR} ]]
then
	NAME="11_baseRecal"
	log $NAME 3
	(. ${CURR_SCRIPT_DIR}/$NAME.sh $NAME) 
	testResult $? $NAME
fi



# Check quality of Recalibration
CURR=$(( CURR + 1 ))
if [[ ${S} -le ${CURR} && ${E} -ge ${CURR} ]]
then
	NAME="12_baseRecalPost"
	log $NAME 3
	(. ${CURR_SCRIPT_DIR}/$NAME.sh $NAME) 
	testResult $? $NAME
fi



# Analyse Covariates and plot
CURR=$(( CURR + 1 ))
if [[ ${S} -le ${CURR} && ${E} -ge ${CURR} ]]
then
	NAME="13_analyse"
	log $NAME 3
	(. ${CURR_SCRIPT_DIR}/$NAME.sh $NAME) 
	testResult $? $NAME
fi


# Print the reads of BQSR
CURR=$(( CURR + 1 ))
if [[ ${S} -le ${CURR} && ${E} -ge ${CURR} ]]
then
	NAME="14_printReads"
	log $NAME 3
	(. ${CURR_SCRIPT_DIR}/$NAME.sh $NAME) 
	testResult $? $NAME
fi



# Validate the final BAM file 
# Generate statistics and plots
CURR=$(( CURR + 1 ))
if [[ ${S} -le ${CURR} && ${E} -ge ${CURR} ]]
then
	NAME="15_validate"
	log $NAME 3
	(. ${CURR_SCRIPT_DIR}/$NAME.sh $NAME) 
	testResult $? $NAME
fi



# Call the variants with Haplotype Caller
CURR=$(( CURR + 1 ))
if [[ ${S} -le ${CURR} && ${E} -ge ${CURR} ]]
then
	NAME="16_haplotype"
	log $NAME 3
	(. ${CURR_SCRIPT_DIR}/$NAME.sh $NAME) 
	testResult $? $NAME
fi



# Call the variants with Haplotype Caller
CURR=$(( CURR + 1 ))
if [[ ${S} -le ${CURR} && ${E} -ge ${CURR} ]]
then
	NAME="17_report"
	log $NAME 3
	(. ${CURR_SCRIPT_DIR}/$NAME.sh $NAME) 
	testResult $? $NAME
fi




log "Pipeline completed sucessfully." 3
log $(printf '#%.0s' $(seq 1 $(($(tput cols)-35)) ) ) 3 2> /dev/null


