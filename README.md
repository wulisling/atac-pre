# atac-pre
version:1.0  
this code treat fastq.gz file to .bam file ready for call peak  
Dependency: trim-galore, bwa, samtools, picard.jar, deeptools  
## NOTE:  
  1. output directory must be the format like [/path/to/my/dir/] which ended with [ / ]  
  2. the 2 fq.gz file must be seperated by [ _ ]
     Example: prefix_R1.fq.gz; prefix_R2.fq.gz, prefix CANNOT contain [ _ ] symbol.  
## usage:  
  ```atac-single.sh -1 [first fq file] -2 [second fq file ] -o [output_dir] -a [bwaindex] -p [process number] -g [genomesize file] -j [picard file]```  
## options:  
        [-1] the first fastq files  
        [-2] the second fastq files  
        [-o] the output directory,must be ended with [/]  
        example:[/home/mypath/]  
        [-a] path to the reference fasta file, for mouse it can be mm10.fa  
        [-p] processes to uss, default:1  
        [-g] genomesize file  
        [-j] path to picard.jar file  
          
## EXAMPLE:  
```atac-single.sh -1 prefix_R1.fq.gz -2 prefix_R2.fq.gz -o /my/path/ -a mm10 -p 4 -g mm10.chrom.size -j /path/to/picard.jar```  
## OUTPUT Files：  
  It output 4 directory under output_dir  
  ### Trim/: 
  containing Trimed fq.gz files from trim_galore  
  ### MAP/: 
  containing prefix.sam file from bwa  
  ### prebam/: 
  containing prebam data  
      prefix.bam, [origin bam from sam file]  
      prefix.sort.bam, [sorted bam file from Previous file]  
      prefix.nodup.bam, [bam file removed duplication with picard from Previous file]  
      prefix.nodup.nomty.bam, [bam file removed chrMT and chrY from Previous file]  
      prefix.fixmate.bam, [bamfile fixmate from Previous file]  
      prefix.piar.sort.bam, [bamfile paired from Previous file]  
  ### shifted/:
  containing shifted bam file  
      prefix.shifted.bam, [bamfile shifted from Previous file]  
      prefix.shifted.sort.bam, [sorted bamfile from Previous file]  
      prefix.shifted.sort.bam.bai, [index file of the Previous file]  
