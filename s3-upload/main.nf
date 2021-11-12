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

/********************************************************************/
/* this block is auto-generated based on info from pkg.json where   */
/* changes can be made if needed, do NOT modify this block manually */
nextflow.enable.dsl = 2
version = '0.3.0'

container = [
    'ghcr.io': 'ghcr.io/icgc-argo/benchmark-data-submission.s3-upload'
]
default_container_registry = 'ghcr.io'
/********************************************************************/


// universal params go here
params.container_registry = ""
params.container_version = ""
params.container = ""

params.cpus = 1
params.mem = 1  // GB
params.publish_dir = ""  // set to empty string will disable publishDir


// tool specific parmas go here, add / change as needed
params.endpoint_url = "https://object.cancercollaboratory.org:9080"
params.bucket_name = "genomics-public-data"
params.payload = ""
params.s3_access_key = ""
params.s3_secret_key = ""
params.upload_files = ""


process s3Upload {
  container "${params.container ?: container[params.container_registry ?: default_container_registry]}:${params.container_version ?: version}"
  publishDir "${params.publish_dir}/${task.process.replaceAll(':', '_')}", mode: "copy", enabled: params.publish_dir

  cpus params.cpus
  memory "${params.mem} GB"

  input:  // input, make update as needed
    val endpoint_url
    val bucket_name
    path payload
    val s3_access_key
    val s3_secret_key
    path upload_files

  script:
    // add and initialize variables here as needed

    """
    main.py \
      -s ${endpoint_url} \
      -b ${bucket_name} \
      -p ${payload} \
      -c ${s3_access_key} \
      -k ${s3_secret_key} \
      -f ${upload_files}
    """
}


// this provides an entry point for this main script, so it can be run directly without clone the repo
// using this command: nextflow run <git_acc>/<repo>/<pkg_name>/<main_script>.nf -r <pkg_name>.v<pkg_version> --params-file xxx
workflow {
  s3Upload(
    params.endpoint_url,
    params.bucket_name,
    file(params.payload),
    params.s3_access_key,
    params.s3_secret_key,
    Channel.fromPath(params.upload_files).collect()
  )
}
