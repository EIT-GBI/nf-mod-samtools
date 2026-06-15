process SAMTOOLS_SORT {
    tag "${meta.id}"

    publishDir "${params.outdir}/sorted", mode: 'link'

    input:
    tuple val(meta), path(sam)

    output:
    tuple val(meta), path("${meta.id}.sorted.bam"), emit: bam

    script:
    def args = task.ext.args ?: ''
    """
    samtools sort \\
        ${args} \\
        -@ ${task.cpus} \\
        -o ${meta.id}.sorted.bam \\
        ${sam}
    """

    stub:
    """
    touch ${meta.id}.sorted.bam
    """
}
