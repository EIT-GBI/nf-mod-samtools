process SAMTOOLS_INDEX {
    tag "${meta.id}"

    publishDir "${params.outdir}/index", mode: 'link'

    input:
    tuple val(meta), path(input)

    output:
    tuple val(meta), path("*.bai"), emit: bai, optional: true
    tuple val(meta), path("*.csi"), emit: csi, optional: true

    script:
    def args = task.ext.args ?: ''
    """
    samtools index \\
        ${args} \\
        -@ ${task.cpus} \\
        ${input}
    """

    stub:
    """
    touch ${input}.bai
    """
}
