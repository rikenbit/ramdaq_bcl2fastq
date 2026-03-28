#!/usr/bin/env nextflow
nextflow.enable.dsl=2

/*
========================================================================================
                         rikenbit/ramdaq_bcl2fastq
========================================================================================
 rikenbit/ramdaq_bcl2fastq Analysis Pipeline.
 #### Homepage / Documentation
 https://github.com/rikenbit/ramdaq_bcl2fastq
----------------------------------------------------------------------------------------
*/

def helpMessage() {
    log.info nfcoreHeader()
    log.info"""
    Usage:
    The typical command for running the pipeline is as follows:
    nextflow run rikenbit/ramdaq_bcl2fastq --run_dir /path/to/run/directory/ -profile docker

    Mandatory arguments:
      -profile [str]                      Configuration profile to use. Can use multiple (comma separated)
                                          Available: docker, singularity

    bcl2fastq
      --run_dir [file]                    Full path to run directory (will parse name of run from the last directory in path)
      --sheet_path [file]                 Full path to sample sheet CSV (Default: <run_dir>/SampleSheet.csv)
      --lane_splitting                     Split FASTQ files by lane (Default: false, i.e. no lane splitting).

    Other options:
      --outdir [file]                     The output directory where the results will be saved (Default: results)
      -name [str]                         Name for the pipeline run. If not specified, Nextflow will automatically generate a random mnemonic
    """.stripIndent()
}

// Show help message
if (params.help) {
    helpMessage()
    exit 0
}

/*
 * SET UP CONFIGURATION VARIABLES
 */

custom_runName = params.name
if (!(workflow.runName ==~ /[a-z]+_[a-z]+/)) {
    custom_runName = workflow.runName
}

// ////////////////////////////////////////////////////
// /* --          VALIDATE INPUTS                 -- */
// ////////////////////////////////////////////////////

if (params.run_dir) { ch_runDir = file(params.run_dir, checkIfExists: true) } else { exit 1, "Run directory not found!" }
if (params.sheet_path) {
    ch_ssheet = file(params.sheet_path, checkIfExists: true)
} else if (params.run_dir) {
    ch_ssheet = file("${params.run_dir}/SampleSheet.csv", checkIfExists: true)
} else {
    exit 1, "Sample sheet not found!"
}
runName = ch_runDir.getName()

// Header log info
log.info nfcoreHeader()
def summary = [:]
if (workflow.revision) summary['Pipeline Release'] = workflow.revision
summary['Run Name']                          = custom_runName ?: workflow.runName
summary['Samplesheet']                       = params.sheet_path ?: "${params.run_dir}/SampleSheet.csv"
summary['Run Directory']                     = params.run_dir
if (params.lane_splitting)                summary['Lane Splitting'] = params.lane_splitting
summary['Max Resources']                     = "$params.max_memory memory, $params.max_cpus cpus, $params.max_time time per job"
if (workflow.containerEngine) summary['Container'] = "$workflow.containerEngine - $workflow.container"
summary['Output dir']                        = params.outdir
summary['Launch dir']                        = workflow.launchDir
summary['Working dir']                       = workflow.workDir
summary['Script dir']                        = workflow.projectDir
summary['User']                              = workflow.userName
summary['Config Profile']                    = workflow.profile
if (params.config_profile_description) summary['Config Description'] = params.config_profile_description
if (params.config_profile_contact)     summary['Config Contact']     = params.config_profile_contact
if (params.config_profile_url)         summary['Config URL']         = params.config_profile_url
log.info summary.collect { k,v -> "${k.padRight(22)}: $v" }.join("\n")
log.info "-\033[2m--------------------------------------------------\033[0m-"

// Check the hostnames against configured profiles
checkHostname()

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
/* --                                                                     -- */
/* --               Main Demultiplexing Processes                         -- */
/* --                                                                     -- */
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

process BCL2FASTQ {
    label 'process_medium'
    publishDir path: "${params.outdir}/${runName}/fastq_files", mode: 'copy'

    input:
    path sheet

    output:
    path "*.fastq.gz"
    path "Reports"
    path "Stats"

    script:
    lane_split = params.lane_splitting ? "" : "--no-lane-splitting"

    """
    bcl2fastq \\
        --runfolder-dir ${params.run_dir} \\
        --output-dir . \\
        --sample-sheet ${sheet} \\
        --interop-dir ${params.run_dir}/InterOp \\
        --input-dir ${params.run_dir}/Data/Intensities/BaseCalls \\
        --stats-dir ./Stats \\
        --reports-dir ./Reports \\
        --loading-threads 4 \\
        --processing-threads ${task.cpus} \\
        --writing-threads 4 \\
        $lane_split
    rm -rf ./Undetermined*
    """
}

///////////////////////////////////////////////////////////////////////////////
/* --                           WORKFLOW                               -- */
///////////////////////////////////////////////////////////////////////////////

workflow {
    BCL2FASTQ(Channel.of(ch_ssheet))
}

///////////////////////////////////////////////////////////////////////////////
/*
* Completion notification
*/
///////////////////////////////////////////////////////////////////////////////

workflow.onComplete {

    c_green  = params.monochrome_logs ? '' : "\033[0;32m"
    c_purple = params.monochrome_logs ? '' : "\033[0;35m"
    c_red    = params.monochrome_logs ? '' : "\033[0;31m"
    c_reset  = params.monochrome_logs ? '' : "\033[0m"

    if (workflow.stats.ignoredCount > 0 && workflow.success) {
        log.info "-${c_purple}Warning, pipeline completed, but with errored process(es) ${c_reset}-"
        log.info "-${c_red}Number of ignored errored process(es) : ${workflow.stats.ignoredCount} ${c_reset}-"
        log.info "-${c_green}Number of successfully ran process(es) : ${workflow.stats.succeedCount} ${c_reset}-"
    }

    if (workflow.success) {
        log.info "-${c_purple}[ramdaq_bcl2fastq]${c_green} Pipeline completed successfully${c_reset}-"
    } else {
        checkHostname()
        log.info "-${c_purple}[ramdaq_bcl2fastq]${c_red} Pipeline completed with errors${c_reset}-"
    }

}

///////////////////////////////////////////////////////////////////////////////
/* --                           FUNCTIONS                              -- */
///////////////////////////////////////////////////////////////////////////////

def nfcoreHeader() {
    // Log colors ANSI codes
    c_black  = params.monochrome_logs ? '' : "\033[0;30m"
    c_blue   = params.monochrome_logs ? '' : "\033[0;34m"
    c_cyan   = params.monochrome_logs ? '' : "\033[0;36m"
    c_dim    = params.monochrome_logs ? '' : "\033[2m"
    c_green  = params.monochrome_logs ? '' : "\033[0;32m"
    c_purple = params.monochrome_logs ? '' : "\033[0;35m"
    c_reset  = params.monochrome_logs ? '' : "\033[0m"
    c_white  = params.monochrome_logs ? '' : "\033[0;37m"
    c_yellow = params.monochrome_logs ? '' : "\033[0;33m"

    return """    ----------------------------------------------------
            ramdaq_bcl2fastq v${workflow.manifest.version}
    ----------------------------------------------------
    """.stripIndent()
}

def checkHostname() {
    def c_reset       = params.monochrome_logs ? '' : "\033[0m"
    def c_white       = params.monochrome_logs ? '' : "\033[0;37m"
    def c_red         = params.monochrome_logs ? '' : "\033[1;91m"
    def c_yellow_bold = params.monochrome_logs ? '' : "\033[1;93m"
    if (params.hostnames) {
        def hostname = "hostname".execute().text.trim()
        params.hostnames.each { prof, hnames ->
            hnames.each { hname ->
                if (hostname.contains(hname) && !workflow.profile.contains(prof)) {
                    log.error "====================================================\n" +
                            "  ${c_red}WARNING!${c_reset} You are running with `-profile $workflow.profile`\n" +
                            "  but your machine hostname is ${c_white}'$hostname'${c_reset}\n" +
                            "  ${c_yellow_bold}It's highly recommended that you use `-profile $prof${c_reset}`\n" +
                            "============================================================"
                }
            }
        }
    }
}
