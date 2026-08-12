// This process does quality/length filtering of reads
// It is designed mainly for use with long-read data, to make sure the MM/ML modified-base calls survive. 


process SAMTOOLS_FILTER {
    tag "${meta.id}"

    publishDir "${params.outdir}/filtered", mode: 'copy'
    
    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("${meta.id}.filtered.bam"), path("${meta.id}.filtered.bam.bai"), emit: filtered

    script:
    def args = task.ext.args ?: ''
    def expr = "avg(qual) >= ${params.filter.min_read_quality} && length(seq) >= ${params.filter.min_read_length}"    """
    """
    samtools view \\
        ${args} \\
        -b \\
        -@ ${task.cpus} \\
        -e '${expr}' \\
        --write-index \\
        -o ${meta.id}.filtered.bam##idx##${meta.id}.filtered.bam.bai \\
        ${bam}
    """ 

    stub:
    """
    touch ${meta.id}.filtered.bam ${meta.id}.filtered.bam.bai
    """
}