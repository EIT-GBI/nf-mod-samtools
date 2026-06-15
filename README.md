# nf-mod-samtools

Nextflow module for Samtools. Used as a git submodule by pipelines.

Image: `ghcr.io/eit-gbi/nf-mod-samtools:latest`

## Processes

Each subtool lives in its own folder (nf-core style), with a `main.nf` process and a `meta.yml`:

| Process | Path | Input → Output |
| --- | --- | --- |
| `SAMTOOLS_SORT` | `sort/main.nf` | `tuple(meta, sam/bam/cram)` → `tuple(meta, sorted.bam)` |
| `SAMTOOLS_INDEX` | `index/main.nf` | `tuple(meta, bam/cram)` → `tuple(meta, bai/csi)` |
| `SAMTOOLS_FAIDX` | `faidx/main.nf` | `tuple(meta, fasta)` → `tuple(meta, fai[, gzi])` |
| `SAMTOOLS_FLAGSTAT` | `flagstat/main.nf` | `tuple(meta, bam/cram)` → `tuple(meta, flagstat)` |

All processes take a `meta` map (`[ id:'test' ]`) and accept extra arguments via `task.ext.args`.

## Use as submodule
```bash
git submodule add https://github.com/CristiSoitu/nf-mod-samtools.git modules/samtools
```

Then in your pipeline:
```groovy
include { SAMTOOLS_SORT     } from './modules/samtools/sort/main.nf'
include { SAMTOOLS_INDEX    } from './modules/samtools/index/main.nf'
include { SAMTOOLS_FAIDX    } from './modules/samtools/faidx/main.nf'
include { SAMTOOLS_FLAGSTAT } from './modules/samtools/flagstat/main.nf'
```
