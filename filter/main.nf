// This process does quality/length filtering of reads
// It is designed mainly for use with long-read data, to make sure the MM/ML modified-base calls survive.

process SAMTOOLS_FILTER {
    tag "${meta.id}"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("${meta.id}.filtered.bam"), path("${meta.id}.filtered.bam.bai"), emit: filtered

    script:
    // The thresholds belong to the module rather than the consuming pipeline:
    // every pipeline sets the same params.filter.* names and the samtools
    // expression is assembled here, once, instead of being re-derived by each
    // caller. A threshold left unset is dropped from the expression; with
    // neither set no -e is passed at all and nothing is filtered out.
    def terms = []
    if( params.filter?.min_read_quality != null )
        terms << "avg(qual) >= ${params.filter.min_read_quality}"
    if( params.filter?.min_read_length != null )
        terms << "length(seq) >= ${params.filter.min_read_length}"
    // The single quotes are load-bearing: they keep && and >= away from the shell.
    def filter_expr = terms ? "-e '${terms.join(' && ')}'" : ''
    def args = task.ext.args ?: ''
    // samtools honours only the last -e it is given, so a pipeline setting both
    // would have one of its two filters silently dropped. Fail loudly instead.
    if( terms && (args =~ /(^|\s)-e(\s|=|$)/) )
        error "SAMTOOLS_FILTER: params.filter.* and an '-e' in ext.args are both set; samtools would silently honour only the latter. Use one or the other."
    """
    samtools view \\
        ${filter_expr} \\
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
