#!/usr/bin/env nextflow

/*
  Copyright (C) 2021,  OICR

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU Affero General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Affero General Public License for more details.

  You should have received a copy of the GNU Affero General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.

  Authors:
    Linda Xiang
*/

nextflow.enable.dsl = 2
version = '0.3.0'

// universal params go here, change default value as needed
params.container = ""
params.container_registry = ""
params.container_version = ""
params.cpus = 1
params.mem = 1  // GB
params.max_retries = 5  // set to 0 will disable retry
params.first_retry_wait_time = 1  // in seconds
params.publish_dir = ""  // set to empty string will disable publishDir

// tool specific parmas go here, add / change as needed
params.study_id = ""
params.analysis_id = ""

params.cleanup = true
params.s3upload = false
params.rdpcupload = true 
params.tempdir = "NO_DIR"

params.analysis_metadata = "NO_FILE"
params.experiment_info_tsv = "NO_FILE1"
params.read_group_info_tsv = "NO_FILE2"
params.file_info_tsv = "NO_FILE3"
params.extra_info_tsv = "NO_FILE4"
params.sequencing_files = []
params.endpoint_url = ""
params.bucket_name = ""
params.s3_access_key = ""
params.s3_secret_key = ""

params.song_url = ""
params.score_url = ""
params.api_token = ""
params.upload = [:]
params.download = [:]
params.s3Up = [:]

download_params = [
    'song_cpus': params.cpus,
    'song_mem': params.mem,
    'score_cpus': params.cpus,
    'score_mem': params.mem,
    'song_url': params.song_url,
    'score_url': params.score_url,
    'api_token': params.api_token,
    'publish_dir': params.publish_dir,
    'max_retries': params.max_retries,
    'first_retry_wait_time': params.first_retry_wait_time,
    *:(params.download ?: [:])
]

upload_params = [
    'song_cpus': params.cpus,
    'song_mem': params.mem,
    'score_cpus': params.cpus,
    'score_mem': params.mem,
    'song_url': params.song_url,
    'score_url': params.score_url,
    'api_token': params.api_token,
    'publish_dir': params.publish_dir,
    'max_retries': params.max_retries,
    'first_retry_wait_time': params.first_retry_wait_time,
    *:(params.upload ?: [:])
]

s3Up_params = [
    'endpoint_url': params.endpoint_url,
    'bucket_name': params.bucket_name,
    's3_access_key': params.s3_access_key,
    's3_secret_key': params.s3_secret_key,
    *:(params.s3Up ?: [:])
]

include { SongScoreDownload as dnld } from './wfpr_modules/github.com/icgc-argo/nextflow-data-processing-utility-tools/song-score-download@2.6.2/main.nf' params(download_params)
include { songGetAnalysis as songGet } from './wfpr_modules/github.com/icgc-argo/nextflow-data-processing-utility-tools/song-score-download@2.6.2/local_modules/song-get-analysis' params(upload_params)
include { SongScoreUpload as upload } from './wfpr_modules/github.com/icgc-argo/nextflow-data-processing-utility-tools/song-score-upload@2.6.1/main.nf' params(upload_params)
include { cleanupWorkdir as cleanup } from './wfpr_modules/github.com/icgc-argo-workflows/data-processing-utility-tools/cleanup-workdir@1.0.0.1/main.nf'
include { payloadGenSeqExperiment as pGenExp } from './wfpr_modules/github.com/icgc-argo-workflows/data-processing-utility-tools/payload-gen-seq-experiment@0.5.0.1/main.nf'
include { popSystemIds as popSids } from './wfpr_modules/github.com/icgc-argo/benchmark-data-submission/pop-system-ids@0.1.0/main.nf' 
include { s3Upload as s3Up } from './wfpr_modules/github.com/icgc-argo/benchmark-data-submission/s3-upload@0.3.1/main.nf' params(s3Up_params)

// please update workflow code as needed
workflow BenchmarkDataSubmissionWf {
  take:  // update as needed
    study_id
    analysis_id
    analysis_metadata
    experiment_info_tsv
    read_group_info_tsv
    file_info_tsv
    extra_info_tsv
    sequencing_files


  main: 
    // detect 
    if (!params.rdpcupload && !params.s3upload) {
      exit 1, "Please specify at least one of `params.rdpcupload` and `params.s3upload` as destination for uploading to either RDPC or S3 bucket.\n"
    }
      
    // detect local mode or not
    local_mode = false
    if ((!analysis_metadata.startsWith("NO_FILE") || !experiment_info_tsv.startsWith("NO_FILE")) && sequencing_files.size() > 0){
        local_mode = true
        if (!params.publish_dir) {
            exit 1, "You specified local sequencing data as input, please also set `params.publish_dir` to keep the output."
        }
        log.info "Run the workflow using local input sequencing data, alignment results will be in: ${params.publish_dir}"

        if (!analysis_metadata.startsWith("NO_FILE")) {
            if (!experiment_info_tsv.startsWith("NO_FILE") ||
                    !read_group_info_tsv.startsWith("NO_FILE") ||
                    !file_info_tsv.startsWith("NO_FILE") ||
                    !extra_info_tsv.startsWith("NO_FILE")
            )  {
                log.info "Use analysis metadata JSON as input, will ignore input: 'experiment_info_tsv', 'read_group_info_tsv', 'file_info_tsv', 'extra_info_tsv'"
            }
            analysis_metadata = file(analysis_metadata)
        } else if (!experiment_info_tsv.startsWith("NO_FILE") &&
                    !read_group_info_tsv.startsWith("NO_FILE") &&
                    !file_info_tsv.startsWith("NO_FILE")
            ) {
            pGenExp(
                file(experiment_info_tsv),
                file(read_group_info_tsv),
                file(file_info_tsv),
                file(extra_info_tsv)
            )
            analysis_metadata = pGenExp.out.payload
        } else {
            exit 1, "To run the workflow using local inputs, please specify metadata in JSON using params.analysis_metadata or metadata in TSVs using params.experiment_info_tsv, params.read_group_info_tsv, params.file_info_tsv and params.extra_info_tsv"
        }

        sequencing_files = Channel.fromPath(sequencing_files)
    } else if (study_id && analysis_id) {
      // download files and metadata from song/score 
      dnld(study_id, analysis_id)
      analysis_metadata = dnld.out.analysis_json
      sequencing_files = dnld.out.files
    } else {
      exit 1, "To use sequencing data from SONG/SCORE as input, please provide `params.study_id`, `params.analysis_id` and other SONG/SCORE params.\n" +
          "Or please provide `params.analysis_metadata` (or `params.experiment_info_tsv`, `params.read_group_info_tsv`, `params.file_info_tsv` and `params.extra_info_tsv`) and `params.sequencing_files` from local files as input."
    }

    // remove system IDs from analysis metadata
    popSids(analysis_metadata)

    // upload to song/score or openstack object store
    if (params.rdpcupload && params.s3upload ) {
      log.info "The data will be uploaded to both OpenStack S3 and RDPC SONG/SCORE as well"
      upload(study_id, popSids.out.payload, sequencing_files)
      // get back song analysis
      songGet(study_id, upload.out.analysis_id)
      s3Up(params.endpoint_url, params.bucket_name, songGet.out.json, params.s3_access_key, params.s3_secret_key, sequencing_files)
    
    } else if ( !params.rdpcupload && params.s3upload ) {
      log.info "The data will be only uploaded to OpenStack S3"
      s3Up(params.endpoint_url, params.bucket_name, analysis_metadata, params.s3_access_key, params.s3_secret_key, sequencing_files)
    
    } else if ( params.rdpcupload && !params.s3upload ) {
      log.info "The data will be only uploaded to RDPC SONG/SCORE"
      upload(study_id, popSids.out.payload, sequencing_files)
    
    } else {
      exit 1, "Please specify `params.rdpcupload` or `params.s3upload` for uploading to either RDPC or S3 bucket.\n"
    }
    
    // cleanup, skip cleanup when running in local mode
    if ( params.cleanup && !local_mode && params.s3upload) {
      cleanup(dnld.out.files.concat(dnld.out.analysis_json, popSids.out.payload).collect(),
        s3Up.out.count())
    } else if ( params.cleanup && !local_mode && !params.s3upload ){
      cleanup(dnld.out.files.concat(dnld.out.analysis_json, popSids.out.payload).collect(),
        upload.out.analysis_id)
    }
  
  emit:  
    payload = popSids.out.payload
    upload_files = sequencing_files
}


// this provides an entry point for this main script, so it can be run directly without clone the repo
// using this command: nextflow run <git_acc>/<repo>/<pkg_name>/<main_script>.nf -r <pkg_name>.v<pkg_version> --params-file xxx
workflow {
  BenchmarkDataSubmissionWf(
    params.study_id,
    params.analysis_id,
    params.analysis_metadata,
    params.experiment_info_tsv,
    params.read_group_info_tsv,
    params.file_info_tsv,
    params.extra_info_tsv,
    params.sequencing_files
  )
}