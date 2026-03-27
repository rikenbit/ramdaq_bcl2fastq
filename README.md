# Nextflow pipeline for bcl2fastq

- rikenbit/ramdaq_bcl2fastq is a Nextflow pipeline for converting and demultiplexing the raw data produced by Illumina sequencing machines (BCL files) into FASTQ files.
- This pipeline can be used as a preprocessor for the [ramdaq](https://github.com/rikenbit/ramdaq).

## Preparing the execution environment

1. Install [`nextflow`](https://nf-co.re/usage/installation) (version `>=21.04.0` required)

2. Install either [`Docker`](https://docs.docker.com/engine/installation/), [`Singularity`](https://www.sylabs.io/guides/3.0/user-guide/), or [`Apptainer`](https://apptainer.org/docs/user/main/quick_start.html) for full pipeline reproducibility (see [docs](https://nf-co.re/usage/configuration#basic-configuration-profiles))

3. Verify the container image is available

```bash
$ docker run --rm biomehub/bcl2fastq2:2.20.0 bcl2fastq --version
bcl2fastq v2.20.0.422
Copyright (c) 2007-2018 Illumina, Inc.
```

## Converting FASTQ files from a BCL file

```bash
# Run bcl2fastq via nextflow
nextflow run rikenbit/ramdaq_bcl2fastq -r main -profile <docker/singularity> --run_dir <directory path>
```

> **Note:** Nextflow caches the pipeline code locally after the first run. If the repository has been updated, use the `-latest` flag to pull the latest version of the specified branch:
> ```bash
> nextflow run rikenbit/ramdaq_bcl2fastq -r main -latest -profile <docker/singularity> --run_dir <directory path>
> ```
### Required parameters
- `-r main`
    - Need to specify explicitly the [revision](https://github.com/rikenbit/ramdaq_bcl2fastq/releases) of the ramdaq_bcl2fastq
- `--run_dir`
    - Full path to the sequencer run directory (the top-level directory containing `SampleSheet.csv` and `Data/Intensities/BaseCalls/`)
    - ex: `/path/to/210101_A00000_0001_XXXXXXXXXX`

### Other options
- `-profile <docker/singularity/apptainer>`
    - Use this parameter to choose a configuration profile. Profiles can give configuration presets for different compute environments.
    - We highly recommend the use of Docker, Singularity, or Apptainer containers for full pipeline reproducibility. If `-profile` is not specified, the pipeline will run locally and expect software to be installed and available on the PATH.
        - `-profile docker` : A generic configuration profile to be used with Docker
        - `-profile singularity` : A generic configuration profile to be used with Singularity
        - `-profile apptainer` : A generic configuration profile to be used with Apptainer
- `--lane_splitting`
    - Split output FASTQ files by lane (Default: `false`, i.e. no lane splitting)
    - ex: `--lane_splitting true`
- `--outdir`
    - Rename output directory name (Default: `results`)
    - The fastq files will be output under `${outdir}/${run directory name}/fastq_files/`