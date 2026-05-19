process SAMTOOLS_SORT {
    tag "${sample}"

    publishDir "${params.outdir}/sorted", mode: 'link'

    input:
    //val sample
    tuple val(sample), path(sam)

    output:
    tuple val(sample), path("${sample}.sorted.bam"), emit: bam

    script:
    def args = task.ext.args ?: ''
    """
    samtools sort \\
        ${args} \\
        -@ ${task.cpus} \\
        -o ${sample}.sorted.bam \\
        ${sam}
    """
}
