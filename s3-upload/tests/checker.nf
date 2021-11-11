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

/*
 This is an auto-generated checker workflow to test the generated main template workflow, it's
 meant to illustrate how testing works. Please update to suit your own needs.
*/

/********************************************************************/
/* this block is auto-generated based on info from pkg.json where   */
/* changes can be made if needed, do NOT modify this block manually */
nextflow.enable.dsl = 2


// tool specific parmas go here, add / change as needed
params.endpoint_url = "https://object.cancercollaboratory.org:9080"
params.bucket_name = "genomics-public-data"
params.payload = ""
params.s3_access_key = ""
params.s3_secret_key = ""
params.upload_files = ""

include { s3Upload } from '../main'

workflow {
  main:
    s3Upload(
      params.endpoint_url,
      params.bucket_name,
      file(params.payload),
      params.s3_access_key,
      params.s3_secret_key,
      Channel.fromPath(params.upload_files).collect()
    )
}
