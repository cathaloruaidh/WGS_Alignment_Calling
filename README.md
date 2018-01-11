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

## `01_index`
**Description** - Index the reference genome with `bwa index`. 

**Input Files** - 

**Output Files** -

## `02_dict`
**Description** - create the sequence ductionary for the reference genome with `picard CreateSequenceDictionary`. 

**Input Files** - 

**Output Files** -

## `03_align`
**Description** - align the paired end FASTQ files to the reference genome with `bwa mem`. See below for notes on the alternate pipeline. 

**Input Files** - 

**Output Files** -

## `04_rg` - 
**Description** - replace the read group with the sample details (**not implemented**)

**Input Files** - 

**Output Files** -

## `05_reorder` - 
**Description** - reorder the BAM file to 

**Input Files** - 

**Output Files** -

## `06_sort`
**Description** - Index the reference genome with `bwa index`. 

**Input Files** - 

**Output Files** -

## `07_validate`
**Description** - Index the reference genome with `bwa index`. 

**Input Files** - 

**Output Files** -

## `08_markDup`
**Description** - Index the reference genome with `bwa index`. 

**Input Files** - 

**Output Files** -

## `09_rtc`
**Description** - Index the reference genome with `bwa index`. 

**Input Files** - 

**Output Files** -

## `10_indelRealign`
**Description** - Index the reference genome with `bwa index`. 

**Input Files** - 

**Output Files** -

## `11_baseRecal`
**Description** - Index the reference genome with `bwa index`. 

**Input Files** - 

**Output Files** -

## `12_baseRecalPost`
**Description** - Index the reference genome with `bwa index`. 

**Input Files** - 

**Output Files** -

## `13_analyse`
**Description** - Index the reference genome with `bwa index`. 

**Input Files** - 

**Output Files** -

## `14_printReads`
**Description** - Index the reference genome with `bwa index`. 

**Input Files** - 

**Output Files** -

## `15_validate`
**Description** - Index the reference genome with `bwa index`. 

**Input Files** - 

**Output Files** -

## `16_haplotype`
## `01_index`
**Description** - Index the reference genome with `bwa index`. 

**Input Files** - 

**Output Files** -
