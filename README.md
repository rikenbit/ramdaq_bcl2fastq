# Nextflow pipeline for bcl2fastq

- rikenbit/ramdaq_bcl2fastq is a Nextflow pipeline for converting and demultiplexing the raw data produced by Illumina sequencing machines (BCL files) into FASTQ files.
- This pipeline can be used as a preprocessor for the [ramdaq](https://github.com/rikenbit/ramdaq).

## Preparing the execution environment

1. Install [`nextflow`](https://nf-co.re/usage/installation)

2. Install either [`Docker`](https://docs.docker.com/engine/installation/) or [`Singularity`](https://www.sylabs.io/guides/3.0/user-guide/) for full pipeline reproducibility (see [docs](https://nf-co.re/usage/configuration#basic-configuration-profiles))

3. Build a Docker image for bcl2fastq with the following command

```bash
docker build -t bcl2fastq2:1.0 github.com/rikenbit/ramdaq_bcl2fastq#main
```
4. Run test

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
nextflow run rikenbit/ramdaq_bcl2fastq -r main -profile <docker/singularity> --run_dir <directory path>
```
### Required parameters
- -r main
    - Need to specify explicitly the [revision](https://github.com/rikenbit/ramdaq_bcl2fastq/releases) of the ramdaq_bcl2fastq
- --run_dir
    - Requires a BaseCalls directory path(full) containing the binary base call files (BCL files)
    - ex: ${required directory path}/Data/Intensities/BaseCalls

### Other options
- -profile <docker/singularity>
    - Use this parameter to choose a configuration profile. Profiles can give configuration presets for different compute environments.
    - We highly recommend the use of Docker or Singularity containers for full pipeline reproducibility. If -profile is not specified, the pipeline will run locally and expect software to be installed and available on the PATH. 
        - -profile docker : A generic configuration profile to be used with Docker
        - -profile singularity : A generic configuration profile to be used with Singularity
- --lane_splitting
    - If this option is specified, output fastq files are split by lane
- --outdir
    - Rename output directory name (Default : results)
    - The fastq files will be output under "${outdir}/${run directory name}/fastq_files/"