# WGSVariantCalling
WGS Variant Calling pipeline from paired-end FASTQ to gVCF

# Dependencies
The pipeline uses the following programs: 
- GATK v 3.4-0-g7e26428
- bwa v 0.7.12-r1039
- samtools 1.4.1
- picard 2.9.2

The following reference datasets are used: 
- GRCh38 reference genome
- dbSNP callset (v 150)
- HapMap

# Help
```
-a, --alt - Run alternate pipeline (mark duplicates) [false]
-c, --clean - Remove all input files once finished [false] 
-d, --dbsnp <FILE> - dbSNP VCF file [v 150]
-e, --end <INT> - Tool to finish on [100]
-f, --file <FILE> - Name of source file. Looks for inputs of the form <FILE>_R1.fq.gz or similar []
-g, --gatk <FILE> - GATK file [GATK 3.4]
-h, --help - Output this message
-m, --mem-min <INT> - Java minimum memory [6G]
-r, --reference <FILE> - FASTA Reference file [GRCh38]
-s, --start <INT> - Tool to start on [0]
-t, --threads <INT> - Number of threads for multithreaded processes [4]
-v, --verbose <INT> - Set verbosity level [3]
-x, --mem-max <INT> Java maximum memory [6G] 
 ```
 
# Pipeline Overview
1. `01_index` - index the reference genome with `bwa index`
2. `02_dict` - create the sequence ductionary for the reference genome with `picard`
3. `03_align` - 
4. `04_rg`
5. `05_reorder`
6. `06_sort`
7. `07_validate`
8. `08_markDup`
9. `09_rtc`
10. `10_indelRealign`
11. `11_baseRecal`
12. `12_baseRecalPost`
13. `13_analyse`
14. `14_printReads`
15. `15_validate`
16. `16_haplotype`
