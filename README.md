# nf-mod-samtools

Nextflow module for Samtools. Used as a git submodule by pipelines.

Image: `ghcr.io/eit-gbi/nf-mod-samtools:latest`

## Processes

- `SAMTOOLS_SORT` — input: `path bam` → output: `path sorted_bam`

## Use as submodule
```bash
git submodule add https://github.com/CristiSoitu/nf-mod-samtools.git modules/samtools
```

Then in your pipeline:
```groovy
include { SAMTOOLS_SORT} from './modules/samtools/main.nf'
```
