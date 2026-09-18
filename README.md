# nf-mod-samtools

Nextflow module for SAMtools (BAM/CRAM manipulation). Used as a git submodule by pipelines.

Image: `ghcr.io/eit-gbi/nf-mod-samtools:v1.0.0`

## Processes

Each subtool lives in its own folder (nf-core style), with a `main.nf`, a
`meta.yml` and an nf-test case under `tests/`.

| Process | Path | Inputs | Emits |
| --- | --- | --- | --- |
| `SAMTOOLS_FAIDX` | `faidx/main.nf` | `tuple val(meta), path(fasta)` | `fai`, `gzi` |
| `SAMTOOLS_FASTQ` | `fastq/main.nf` | `tuple val(meta), path(bam)` | `reads` |
| `SAMTOOLS_FILTER` | `filter/main.nf` | `tuple val(meta), path(bam)` | `filtered` |
| `SAMTOOLS_FLAGSTAT` | `flagstat/main.nf` | `tuple val(meta), path(bam)` | `flagstat` |
| `SAMTOOLS_INDEX` | `index/main.nf` | `tuple val(meta), path(bam)` | `bam` |
| `SAMTOOLS_SORT` | `sort/main.nf` | `tuple val(meta), path(sam)` | `bam` |

## Publishing

These processes do **not** publish their own outputs. Publishing is the
consuming pipeline's job, via a workflow `output {}` block. This keeps the
module reusable across pipelines that want different result layouts.

## Tool arguments

Flags are passed through `task.ext.args` (and `args2`/`args3` where a process
runs more than one command) rather than read from pipeline `params`, so the
module never depends on a particular pipeline's parameter names:

```groovy
process {
    withName: SAMTOOLS_FAIDX {
        ext.args = '--some-flag'
    }
}
```

`SAMTOOLS_FILTER` takes its samtools filter expression this way. The single
quotes are load-bearing: they keep `&&` and `>=` away from the shell.

```groovy
process {
    withName: SAMTOOLS_FILTER {
        ext.args = "-e 'avg(qual) >= 30 && length(seq) >= 150'"
    }
}
```

## Use as submodule

Pin to a release tag rather than a branch, so pipeline runs stay reproducible:

```bash
git submodule add https://github.com/EIT-GBI/nf-mod-samtools.git modules/samtools
git -C modules/samtools checkout v1.0.0
```

Then include the module's container config from your `nextflow.config`. Nextflow
does not read a submodule's config on its own, so without this line the
processes have no image:

```groovy
includeConfig 'modules/samtools/conf/module.config'
```

`conf/module.config` pins the image to the version built from this same commit,
and carries no `manifest {}` block, so it will not overwrite your pipeline's
own manifest. Override it in your pipeline with a `withName` selector if needed.

And include the processes:

```groovy
include { SAMTOOLS_FAIDX } from './modules/samtools/faidx/main.nf'
include { SAMTOOLS_FASTQ } from './modules/samtools/fastq/main.nf'
include { SAMTOOLS_FILTER } from './modules/samtools/filter/main.nf'
include { SAMTOOLS_FLAGSTAT } from './modules/samtools/flagstat/main.nf'
include { SAMTOOLS_INDEX } from './modules/samtools/index/main.nf'
include { SAMTOOLS_SORT } from './modules/samtools/sort/main.nf'
```

## Requirements

Nextflow 26.04.4 or newer.

## Tests

`nf-test test`. Every process has a stub test covering wiring and output names,
and tests that run samtools for real against
`ghcr.io/eit-gbi/nf-mod-samtools:latest` and snapshot what comes out. The real
tests need Docker and the `nft-bam` plugin declared in `nf-test.config`, which
nf-test fetches on first run. They share `tests.config` at the repo root;
`tests-filter.config` adds a filter expression through `ext.args`.

Processes emitting a BAM (`SAMTOOLS_FILTER`, `SAMTOOLS_SORT`) snapshot
read-level checksums rather than the file checksum: samtools records its own
command line, including `-@ <cpus>`, in an `@PG` header line, so the file
checksum changes whenever the config does. Processes emitting text (`FAIDX`,
`FLAGSTAT`) or a deterministic file (`FASTQ`, whose gzip records no mtime when
compressing stdin) are snapshotted directly.

`SAMTOOLS_FILTER` also asserts the filter expression itself, recovered from that
`@PG` record, which confirms the quoting in `ext.args` survives the shell.

Note that a stub test cannot cover any of this: `-stub-run` replaces the whole
script block, so the tool never runs.

## Releasing

Merging a PR to `main` with exactly one `bump:patch`, `bump:minor` or
`bump:major` label bumps `manifest.version` in `nextflow.config`, tags the
release and publishes the container image.
