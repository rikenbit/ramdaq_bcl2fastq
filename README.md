# Nextflow pipeline for bcl2fastq

- rikenbit/ramdaq_bcl2fastq is a bioinformatics pipeline used to demultiplex the raw data produced by Illumina sequencing machines
- This pipeline can be used as a preprocessor for the [ramdaq](https://github.com/rikenbit/ramdaq).

## Preparing the execution environment

- Install [`nextflow`](https://nf-co.re/usage/installation)

- Install either [`Docker`](https://docs.docker.com/engine/installation/) or [`Singularity`](https://www.sylabs.io/guides/3.0/user-guide/) for full pipeline reproducibility (see [docs](https://nf-co.re/usage/configuration#basic-configuration-profiles))

- Build a Docker image for bcl2fastq with the following command

```bash
docker build -t bcl2fastq2:1.0 github.com/rikenbit/ramdaq_bcl2fastq#main
```
- Run test

```bash
$ docker run --rm bcl2fastq2:1.0 bcl2fastq --help
BCL to FASTQ file converter
bcl2fastq v2.17.1.14
Copyright (c) 2007-2015 Illumina, Inc.
...
```

## Converting FASTQ files from a BCL file

```bash
# Run bcl2fastq via nextflow
nextflow rikenbit/ramdaq_bcl2fastq -profile <docker/singularity> --run_dir <directory path>
```

### Other options
- --run_dir
    - Requires a BaseCalls directory path(full) containing the binary base call files (BCL files)
    - ex: ${required directory path}/Data/Intensities/BaseCalls
- --lane_splitting
    - If this option is specified then split output fastq files across lanes
- --outdir
    - Rename output directory name (Default : results)
    - The fastq files will be output under "${outdir}/${run directory name}/fastq_files/"