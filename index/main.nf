process SAMTOOLS_INDEX {
    tag "${meta.id}"

    publishDir "${params.outdir}/alignment", mode: 'link'

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path(bam), path("*.bai"), emit: bam

    script:
    def args = task.ext.args ?: ''
    """
    samtools index \\
        ${args} \\
        -@ ${task.cpus} \\
        ${bam}
    """

    stub:
    """
    touch ${bam}.bai
    """
}
