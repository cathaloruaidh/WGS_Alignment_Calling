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




### Create a pdf report on the pipeline. 

if [[ -f ${RESULTS_DIR}/${REPORT_TEX} ]]
then
	rm ${RESULTS_DIR}/${REPORT_TEX%tex}*
fi


sed -i '/BIN/,$!d' ${RESULTS_DIR}/${DUP_MET} 

Rscript --vanilla -e "library(data.table) ; \
data <- read.table('${RESULTS_DIR}/${DUP_MET}', header = T) ; \
pdf('${GRAPHICS_DIR}/${DUP_MET}.pdf') ; \
plot(data, type = 'l', col = 'red', xlab = 'Sequencing Multiple', \
ylab = 'Coverage Return Multiple', main = 'ROI on Higher Sequencing') ; \
abline(h = max(data[,2]), col = 'blue') ; \
grid(col = 'dimgrey')"


ls -hog --time-style=+"%Y-%m-%d_%H:%M:%S" ${RESULTS_DIR} | tail -n +2 | awk 'BEGIN{OFS="\t"} ; {print $3,$4,$5}' >> ${TEMP_DIR}/list.txt

printf '\\documentclass[a4paper,11pt]{article}\n' >> ${RESULTS_DIR}/${REPORT_TEX}
printf '\\usepackage{amsmath, amsfonts, setspace, longtable, setspace, amssymb, fullpage, graphicx, pdfpages, underscore, fancyvrb}\n\n' >> ${RESULTS_DIR}/${REPORT_TEX}
printf '\\usepackage{grffile}\n\n' >> ${RESULTS_DIR}/${REPORT_TEX}
printf '\\input{/home/shared/tools/latex/macros.tex}\n' >> ${RESULTS_DIR}/${REPORT_TEX}
printf '\\parindent 0pt\n' >> ${RESULTS_DIR}/${REPORT_TEX}

printf '\\title{NGS Variant Calling Pipeline for %s}\n\n'  $( echo ${OUTPUT_PREFIX} | sed -e 's/_/\\string_/g') >> ${RESULTS_DIR}/${REPORT_TEX}
printf '\\author{Cathal Ormond}\n' >> ${RESULTS_DIR}/${REPORT_TEX}
printf '\\date{%s}\n\n' "$(date '+%Y/%m/%d at %H:%M:%S')" >> ${RESULTS_DIR}/${REPORT_TEX}

printf '\\begin{document}\n\n\n' >> ${RESULTS_DIR}/${REPORT_TEX}
printf '\\onehalfspacing\n' >> ${RESULTS_DIR}/${REPORT_TEX}
printf '\\maketitle\n' >> ${RESULTS_DIR}/${REPORT_TEX}
printf '\\tableofcontents\n' >> ${RESULTS_DIR}/${REPORT_TEX}
printf '\\newpage\n\n\n' >> ${RESULTS_DIR}/${REPORT_TEX}

#printf '\\section{List of Results Files}\n' >> ${RESULTS_DIR}/${REPORT_TEX}
#printf '\\codeLine{\\input{%s}}\n\n\n' ${TEMP_DIR}/list.txt >> ${RESULTS_DIR}/${REPORT_TEX}
#printf '\\newpage\n\n' >> ${RESULTS_DIR}/${REPORT_TEX}

printf '\\section{Post Alignment Validation}\n' >> ${RESULTS_DIR}/${REPORT_TEX}
printf '\\begin{Verbatim}[fontsize=\scriptsize, frame=single, tabsize=4]\n' >> ${RESULTS_DIR}/${REPORT_TEX}
printf '%s\n' "$( cat ${RESULTS_DIR}/${FIRST_VAL})" >> ${RESULTS_DIR}/${REPORT_TEX}
printf '\\end{Verbatim}\n\n' >> ${RESULTS_DIR}/${REPORT_TEX}
printf '\\newpage\n\n' >> ${RESULTS_DIR}/${REPORT_TEX}

printf '\\section{Pre Calling Validation}\n' >> ${RESULTS_DIR}/${REPORT_TEX}
printf '\\begin{Verbatim}[fontsize=\scriptsize, frame=single, tabsize=4]\n' >> ${RESULTS_DIR}/${REPORT_TEX}
printf '%s\n' "$( cat ${RESULTS_DIR}/${FINAL_VAL})" >> ${RESULTS_DIR}/${REPORT_TEX}
printf '\\end{Verbatim}\n\n' >> ${RESULTS_DIR}/${REPORT_TEX}
printf '\\newpage\n\n' >> ${RESULTS_DIR}/${REPORT_TEX}

printf '\\section{Duplication ROI}\n\n' >> ${RESULTS_DIR}/${REPORT_TEX}
printf '\\begin{center}\n' >> ${RESULTS_DIR}/${REPORT_TEX}
printf '\t\\includegraphics{%s}\n' $( echo ${GRAPHICS_DIR}/${DUP_MET}.pdf | sed -e 's/_/\\string_/g' ) >> ${RESULTS_DIR}/${REPORT_TEX}
printf '\\end{center}\n\n\n' >> ${RESULTS_DIR}/${REPORT_TEX}

printf '\\section{BQSR Covariation}\n' >> ${RESULTS_DIR}/${REPORT_TEX}
printf '\\includepdf[pages=-,landscape=true]{%s}\n' $( echo ${GRAPHICS_DIR}/${BQSR_PLOTS} | sed -e 's/_/\\string_/g') >> ${RESULTS_DIR}/${REPORT_TEX}

printf '\\section{Final \\code{BAM} Statistics}\n' >> ${RESULTS_DIR}/${REPORT_TEX}
for FILE in `ls ${GRAPHICS_DIR}/${OUTPUT_PREFIX}*png`
do
	MIDDLE=`basename ${FILE}`
	printf '\\subsection{%s}\n' ${MIDDLE%.png} >> ${RESULTS_DIR}/${REPORT_TEX}
	printf '\\begin{center}\n' >> ${RESULTS_DIR}/${REPORT_TEX}
	printf '\t\\includegraphics{%s}\n' $( echo ${FILE} | sed -e 's/_/\\string_/g' ) >> ${RESULTS_DIR}/${REPORT_TEX}
	printf '\\end{center}\n' >> ${RESULTS_DIR}/${REPORT_TEX}
	printf '\\newpage\n\n' >> ${RESULTS_DIR}/${REPORT_TEX}
done
printf '\n' >> ${RESULTS_DIR}/${REPORT_TEX}
printf '\n' >> ${RESULTS_DIR}/${REPORT_TEX}
printf '\n' >> ${RESULTS_DIR}/${REPORT_TEX}
printf '\n' >> ${RESULTS_DIR}/${REPORT_TEX}
printf '\n' >> ${RESULTS_DIR}/${REPORT_TEX}
printf '\n' >> ${RESULTS_DIR}/${REPORT_TEX}
printf '\n' >> ${RESULTS_DIR}/${REPORT_TEX}
printf '\n' >> ${RESULTS_DIR}/${REPORT_TEX}
printf '\\end{document}\n' >> ${RESULTS_DIR}/${REPORT_TEX}


pdflatex -output-directory ${RESULTS_DIR} ${RESULTS_DIR}/${REPORT_TEX} \
> ${LOG_DIR}/${OUTPUT_PREFIX}.ALIGN.${1}.log #2>&1

pdflatex -output-directory ${RESULTS_DIR} ${RESULTS_DIR}/${REPORT_TEX} \
> ${LOG_DIR}/${OUTPUT_PREFIX}.ALIGN.${1}.log #2>&1

