# nf-mod-samtools

Nextflow module for SAMtools (BAM/CRAM manipulation). Used as a git submodule by pipelines.

Image: `ghcr.io/eit-gbi/nf-mod-samtools:v0.0.0`

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

Plain tool flags are passed through `task.ext.args` (and `args2`/`args3` where a
process runs more than one command):

```groovy
process {
    withName: SAMTOOLS_FAIDX {
        ext.args = '--some-flag'
    }
}
```

## Module-owned parameters

Where a setting is a property of what the module *does* rather than of a
particular pipeline, the module owns it: it declares the `params` names and
builds the tool invocation from them, so every consuming pipeline configures it
the same way instead of each one re-deriving the same expression.

`SAMTOOLS_FILTER` is the first process to work this way:

| Param | Meaning |
| --- | --- |
| `params.filter.min_read_quality` | minimum mean base quality (`avg(qual)`) |
| `params.filter.min_read_length` | minimum read length (`length(seq)`) |

The module turns these into the samtools filter expression:

```groovy
params {
    filter {
        min_read_quality = 10
        min_read_length  = 500
    }
}
// -> samtools view -e 'avg(qual) >= 10 && length(seq) >= 500'
```

Either threshold may be left unset, in which case its term is dropped. With
neither set no `-e` is passed and no reads are filtered, so pipelines that do
not set `params.filter` keep their previous behaviour.

Do **not** declare defaults for these in `conf/module.config`. Pipelines
normally `includeConfig` that file *after* their own `params` block, so a
default there would silently overwrite whatever the pipeline had set.

Setting `params.filter.*` and also passing `-e` through `ext.args` is an error:
samtools honours only the last `-e`, which would silently drop one of the two
filters, so the process fails instead.

## Use as submodule

Pin to a release tag rather than a branch, so pipeline runs stay reproducible:

```bash
git submodule add https://github.com/EIT-GBI/nf-mod-samtools.git modules/samtools
git -C modules/samtools checkout v0.0.0
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

`nf-test test`. Most processes are covered by stub tests, which check wiring and
output names without running the tool.

`SAMTOOLS_FILTER` additionally has tests that run samtools for real, against
`ghcr.io/eit-gbi/nf-mod-samtools:latest`, and snapshot what comes out. These
need Docker, and the `nft-bam` plugin declared in `nf-test.config`, which
nf-test fetches on first run.

They snapshot read-level checksums and read counts rather than the BAM file
checksum: samtools records its own command line, including `-@ <cpus>`, in an
`@PG` header line, so the file checksum changes whenever the config does. They
also assert the filter expression itself, recovered from that `@PG` record,
which pins the comparison operators - read counts alone cannot tell `>=` from
`>` unless the test data happens to sit on the boundary.

Note that a stub test cannot cover any of this: `-stub-run` replaces the whole
script block, so neither the expression nor the `ext.args` guard is reached.

## Releasing

Merging a PR to `main` with exactly one `bump:patch`, `bump:minor` or
`bump:major` label bumps `manifest.version` in `nextflow.config`, tags the
release and publishes the container image.
