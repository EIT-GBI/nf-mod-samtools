process SAMTOOLS_FAIDX {
    tag "${meta.id}"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*.fai"), emit: fai
    tuple val(meta), path("*.gzi"), emit: gzi, optional: true

    script:
    def args = task.ext.args ?: ''
    """
    samtools faidx \\
        ${args} \\
        ${fasta}
    """

    stub:
    """
    touch ${fasta}.fai
    """
}
