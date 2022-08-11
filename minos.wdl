# Author: Ash O'Farrell

# This workflow is an attempt to WDLize the full process described by Hunt et al in
# the paper "Minos: variant adjucation and joint genotyping of cohorts of bacterial genomes"
# https://genomebiology.biomedcentral.com/articles/10.1186/s13059-022-02714-x#Sec10

version 1.0

task minos_adjudicate {
	input {
		File ref
		File reads
		File vcf1
		File vcf2

		# runtime attributes
		Int addldisk = 1
		Int cpu = 4
		Int retries = 1
		Int memory = 8
		Int preempt = 2
	}
	# Estimate disk size required
	Int ref_size = ceil(size(ref, "GB"))
	Int finalDiskSize = 2*ref_size + addldisk

	String ref_basename = basename(ref)

	command <<<
		# softlinks don't seem to cut it here
		set -eux -o pipefail
		cp ~{ref} .
		minos adjudicate --reads ~{reads} outdir ~{ref} ~{vcf1} ~{vcf2}
	>>>
	
	runtime {
		cpu: cpu
		docker: "quay.io/aofarrel/minosmirror"
		disks: "local-disk " + finalDiskSize + " HDD"
		maxRetries: "${retries}"
		memory: "${memory} GB"
		preemptibles: "${preempt}"
	}
}

workflow Minos {
	input {
		File ref
		File reads  # should be a bam file
		File vcf1
		File vcf2
		Array[File]? genome_index  # TODO: Does this actually make things faster?
	}

	call minos_adjudicate {
		input:
			ref = ref,
			reads = reads,
			vcf1 = vcf1,
			vcf2 = vcf2
	}

	meta {
		author: "Ash O'Farrell"
		email: "aofarrel@ucsc.edu"
	}
}
