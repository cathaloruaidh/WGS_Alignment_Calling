# WGSVariantCalling
WGS Variant Calling pipeline from paired-end FASTQ to gVCF

# Dependencies
The pipeline uses the following programs: 
- `gatk` 3.4-0-g7e26428
- `bwa` 0.7.12-r1039
- `samtools` 1.4.1
- `picard` 2.9.2
- `samblaster` 0.1.24

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

**Input Files** - `REFERENCE.fa`

**Output Files** - `REFERENCE.fa.amb`, `REFERENCE.fa.ann`, `REFERENCE.fa.bwt`, `REFERENCE.fa.pac` and `REFERENCE.fa.sa` files. 

## `02_dict`
**Description** - create the sequence ductionary for the reference genome with `picard CreateSequenceDictionary`. 

**Input Files** - `REFERENCE.fa`

**Output Files** - `REFERENCE.dict`

## `03_align`
**Description** - align the paired end FASTQ files to the reference genome with `bwa mem`. The alternate pipeline (specified by `-a, --alt`) marks duplicates reads at this stage with `samblaster`. Default is to mark duplicates with `picard` later. 

**Input Files** - `FILE_R1.fastq` and `FILE_R2.fastq` (`gzip`d files accepted). 

**Output Files** - `FILE.bam`

## `04_rg`
**Description** - replace the read group with the sample details (**not implemented**). If no read group data is specifies, the input BAM is unchanged. 

**Input Files** - `FILE.bam`

**Output Files** - `FILE.rg.bam`

## `05_reorder`
**Description** - reorder the BAM file to the format the Broad Institute tools expect with `picard ReorderSam`

**Input Files** - `FILE.rg.bam`

**Output Files** - `FILE.rg.reorder.bam`

## `06_sort`
**Description** - sort the BAM file by coordinate and modify the headers with `picard SortSam` 

**Input Files** - `FILE.rg.reorder.bam`

**Output Files** - `FILE.rg.reorder.sort.bam`

## `07_validate`
**Description** - validate the BAM with `picard ValidateSamFile`. There should be no errors at this stage, as only Broad Institute tools have been used (and `bwa mem` invoked the `-M` flag)

**Input Files** - `FILE.rg.reorder.sort.bam`

**Output Files** - `FILE.rg.reorder.sort.validate.txt`

## `08_markDup`
**Description** - mark duplicates reads with `picard MarkDuplicateReads`. Note that this step is skipped for the alternate pipeline. Also outputs duplication metrics. 

**Input Files** - `FILE.rg.reorder.sort.bam`

**Output Files** - `FILE.rg.reorder.sort.nodup.bam` and `FILE.rg.reorder.sort.metrics`

## `09_rtc`
**Description** - select regions around indels to be realigned with `gatk -T RealignerTargetCreator`. 

**Input Files** - `FILE.rg.reorder.sort.nodup.bam`

**Output Files** - `FILE.rg.reorder.sort.nodup.realign.intervals`

## `10_indelRealign`
**Description** - performs local realignment around indels with `gatk -T IndelRealigner` using the intervals from the previous step. 

**Input Files** - `FILE.rg.reorder.sort.nodup.bam` and `FILE.rg.reorder.sort.nodup.realign.intervals`

**Output Files** - `FILE.rg.reorder.sort.nodup.realign.bam`

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
**Description** - Index the reference genome with `bwa index`. 

**Input Files** - 

**Output Files** -
