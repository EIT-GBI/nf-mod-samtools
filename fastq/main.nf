// This converts reads from unaligned BAM to FASTQ format. 

process SAMTOOLS_FASTQ {
    tag "${meta.id}"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("${meta.id}.fastq.gz"), emit: reads

    script:
    def args = task.ext.args ?: ''
    """
    samtools fastq \\
        ${args} \\
        -@ ${task.cpus} \\
        ${bam} \\
        | gzip > ${meta.id}.fastq.gz
    """

    stub:
    """
    touch ${meta.id}.fastq.gz
    """
}