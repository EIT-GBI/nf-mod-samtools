process SAMTOOLS_FLAGSTAT {
    tag "${meta.id}"

    publishDir "${params.outdir}/qc/flagstat", mode: 'link'


    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("${meta.id}.flagstat.txt"), emit: flagstat

    script:
    def args = task.ext.args ?: ''
    """
    samtools flagstat \\
        ${args} \\
        -@ ${task.cpus} \\
        ${bam} \\
        > ${meta.id}.flagstat.txt
    """

    stub:
    """
    touch ${meta.id}.flagstat.txt
    """
}
