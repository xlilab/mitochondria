#!/usr/bin/env bash
#Description: 该脚本需放置于组织所在目录运行
#Author: Wang Zhenguo
#Created Time: 2021/10/31 14:35

# set -e -u -o pipefail
ulimit -u 65535

echo "Usage: sh $0 [ tissue.list ]"

TISSUES=$1
BAMDIR=/home/wangzhenguo/data/datasets/gtex/RNA_bam/v8/RNAseq_bam/
WORKDIR=`pwd`

run_single_tissue(){
	local tissue=$1
	local BAMDIR=$2
	local WORKDIR=$3

	echo "running $tissue"
	if [ -d $tissue ]
	then
		cd $tissue
	else
		mkdir $tissue
		cd $tissue
		ln -s /home/wangzhenguo/tools/cromwell-52.jar
		ln -s /home/wangzhenguo/code/pipeline/mitochondria_m2_RNA_wdl/mitochondria_m2_RNA_wdl/
		ln -s /home/wangzhenguo/code/pipeline/mitochondria_m2_RNA_wdl/rename_cromwell_executions_and_extract_results.sh 
		ln -s /home/wangzhenguo/code/pipeline/mitochondria_m2_RNA_wdl/run_gatk_mitochondria_rna_pipeline_with_multi_samples.sh
	fi
	
	if [ -f remained_sample.list ]
	then
		if [ -s remained_sample.list ]
		then
			sh run_gatk_mitochondria_rna_pipeline_with_multi_samples.sh remained_sample.list $tissue
		fi
	else
		ls $BAMDIR/$tissue/*bam |\
			grep -f /home/wangzhenguo/data/scientific_project/mitochondrial_genome/variant_calling/gtex_838_individuals.id |\
			sed 's/.*\(GTEX-.\{2,\}\.Aligned\).*/\1/;s/\.Aligned//' \
			> gtex_${tissue}_rnaseq.list
		wait
		sh run_gatk_mitochondria_rna_pipeline_with_multi_samples.sh gtex_${tissue}_rnaseq.list $tissue
	fi
	wait
	
	sh rename_cromwell_executions_and_extract_results.sh
	wait
	ls cromwell-executions/MitochondriaPipeline/ >finished_sample.list
	wait
	grep -vf finished_sample.list gtex_${tissue}_rnaseq.list >remained_sample.list
	wait
	# find cromwell-executions/MitochondriaRnaPipeline/ -name output-noquotes |xargs awk '/GTEX/ {print $1"\t"$6"\t"$7}' |sort |sed 's/\(GTEX-[0-9A-Z]*\)-[-0-9A-Z]*/\1/' >gtex_${tissue}.haplogroup
	# wait
	
	echo "finish $tissue"
	
	cd $WORKDIR
}

export -f run_single_tissue
parallel --jobs 2  --xapply run_single_tissue ::: `cat $TISSUES` ::: $BAMDIR ::: $WORKDIR
