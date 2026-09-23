// This builds a consensus sequence per reference contig from aligned reads.
// The input BAM must be coordinate-sorted. Output is FASTA by default; pass
// mode and quality options (e.g. -a --show-del yes -d 10) through ext.args.

process SAMTOOLS_CONSENSUS {
    tag "${meta.id}"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("${meta.id}.consensus.fa"), emit: fasta

    script:
    def args = task.ext.args ?: ''
    """
    samtools consensus \\
        ${args} \\
        -@ ${task.cpus} \\
        -o ${meta.id}.consensus.fa \\
        ${bam}
    """

    stub:
    """
    touch ${meta.id}.consensus.fa
    """
}
