# Author: Ash O'Farrell

# This workflow is an attempt to WDLize the full process described by Hunt et al in
# the paper "Minos: variant adjucation and joint genotyping of cohorts of bacterial genomes"
# https://genomebiology.biomedcentral.com/articles/10.1186/s13059-022-02714-x#Sec10

version 1.0

task minos_adjudicate {
	input {
		File ref
		File reads
		Array[File] vcfs

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
		set -eux -o pipefail
		cp ~{ref} .  # softlinks don't seem to cut it here
		minos adjudicate --reads ~{reads} outdir ~{ref} ~{sep=" " vcfs}
	>>>

	output {
		Array[File] minos_outs = glob("outdir/*")
	}
	
	runtime {
		cpu: cpu
		docker: "quay.io/aofarrel/minosmirror"
		disks: "local-disk " + finalDiskSize + " HDD"
		maxRetries: "${retries}"
		memory: "${memory} GB"
		preemptibles: "${preempt}"
	}
}

workflow Minos_Adjudicate {
	input {
		File ref
		File reads  # should be a bam file
		Array[File] vcfs
		Array[File]? genome_index  # TODO: Does this actually make things faster?
	}

	call minos_adjudicate {
		input:
			ref = ref,
			reads = reads,
			vcfs = vcfs
	}

	meta {
		author: "Ash O'Farrell"
		email: "aofarrel@ucsc.edu"
	}
}
