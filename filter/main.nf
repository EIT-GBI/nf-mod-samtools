// This process does quality/length filtering of reads
// It is designed mainly for use with long-read data, to make sure the MM/ML modified-base calls survive. 

process SAMTOOLS_FILTER {
    tag "${meta.id}"

    
    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("${meta.id}.filtered.bam"), path("${meta.id}.filtered.bam.bai"), emit: filtered

    script:
    def args = task.ext.args ?: ''   // e.g. -e 'avg(qual) >= 10 && length(seq) >= 500'
    """
    samtools view \\
        ${args} \\
        -b \\
        -@ ${task.cpus} \\
        --write-index \\
        -o ${meta.id}.filtered.bam##idx##${meta.id}.filtered.bam.bai \\
        ${bam}
    """ 

    stub:
    """
    touch ${meta.id}.filtered.bam ${meta.id}.filtered.bam.bai
    """
}