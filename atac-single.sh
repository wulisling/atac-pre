#!/bin/bash

while getopts ":o:p:a:g:j:1:2:" opt
do
 case $opt in 
  1)
  one=$OPTARG
  ;;
  2)
  two=$OPTARG
  ;;
  o)
  outputdir=$OPTARG
  ;;
  p)
  process=$OPTARG
  ;;
  a)
  bwaindex=$OPTARG
  ;;
  g)
  genomesize=$OPTARG
  ;;
  j)
  picardrun=$OPTARG
  ;;
  ?)
  printf "[usage] atac-single.sh -1 [first fq file] -2 [second fq file ] -o [output_dir] -a [bwaindex] -p [process number] -g [genomesize file] -j [picard file] \n"
  printf "version:1.0 \n"
  printf "options: \n"
  printf "	[-1] the first fastq files \n"
  printf "	[-2] the second fastq files \n"
  printf "	[-o] the output directory,must be ended with [/] \n 	example:[/home/mypath/] \n"
  printf "	[-a] path to the reference fasta file, for mouse it can be mm10.fa \n"
  printf "	[-p] processes to uss, default:1 \n"
  printf "	[-g] genomesize file \n"
  printf "	[-j] path to picard.jar file \n"
  exit 1
  esac
done
process=${process:-1} && \
#defalt process=1
outputdir=${outputdir:-.}  && \
#defalt outputdir is the current directory
set -e
if [[ ! $one || ! $two || ! $outputdir || ! $process || ! $bwaindex || ! $genomesize || ! $picardrun ]]
then
echo "lose important parameter , please use [-h] for help"
exit 1
fi
prefix=$(echo $one |rev| cut -d '/' -f 1 |rev |cut -d '_' -f 1) && \
echo " run for sample $prefix ..."  && \
echo " Trimming for $prefix ..."  && \
mkdir -p ${outputdir}Trim && \
trim_galore -j $process --quality 20 --paired ${one} ${two} -o ${outputdir}Trim && \

echo "Mapping for $prefix ..."  && \
mkdir -p ${outputdir}MAP  && \
bwa mem -t $process -o ${outputdir}MAP/${prefix}.sam ${bwaindex} ${outputdir}Trim/${prefix}_R1_val_1.fq.gz ${outputdir}Trim/${prefix}_R2_val_2.fq.gz && \

echo "samtool transition" && \
mkdir -p ${outputdir}prebam && \
samtools view -bhS -t $genomesize -o ${outputdir}prebam/${prefix}.bam ${outputdir}MAP/${prefix}.sam -@ $process  && \

samtools sort -@ $process  -o ${outputdir}prebam/${prefix}.sort.bam ${outputdir}prebam/${prefix}.bam  && \
echo "remove Duplication for $prefix ..." && \
java -jar ${picardrun} MarkDuplicates M=dupstats REMOVE_DUPLICATES=TRUE \
 I=${outputdir}prebam/${prefix}.sort.bam \
 O=${outputdir}prebam/${prefix}.nodup.bam  && \
echo "remove Mt and Y chromosome for $prefix ..." && \
samtools view  -h ${outputdir}prebam/${prefix}.nodup.bam | awk '$3 != "chrM" {print $0}'|awk '$3 != "chrY" {print $0}'|samtools view -Sb  > ${outputdir}prebam/${prefix}.nodup.nomty.bam  && \

samtools sort -@ $process -n ${outputdir}prebam/${prefix}.nodup.nomty.bam | samtools fixmate - ${outputdir}prebam/${prefix}.fixmate.bam  && \

mkdir -p ${outputdir}bam && \
samtools view -f 2 -bF 12 ${outputdir}prebam/${prefix}.fixmate.bam |samtools sort -o ${outputdir}bam/${prefix}.pair.sort.bam  && \

samtools index ${outputdir}bam/${prefix}.pair.sort.bam  && \

echo "ATAC shifting for $prefix bam file ..." && \
mkdir -p  ${outputdir}shifted && \
alignmentSieve -b ${outputdir}bam/${prefix}.pair.sort.bam -o ${outputdir}shifted/${prefix}.shifted.bam --ATACshift -p $process && \

echo "Sorting ..." && \
samtools sort ${outputdir}shifted/${prefix}.shifted.bam -o ${outputdir}shifted/${prefix}.shifted.sort.bam -@ $process && \
samtools index ${outputdir}shifted/${prefix}.shifted.sort.bam && \
echo "Done!"
