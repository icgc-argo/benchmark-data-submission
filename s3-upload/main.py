#!/usr/bin/env python3

import os
import sys
import json
import argparse
import subprocess


def run_cmd(cmd):
    stderr, p, success = '', None, True
    try:
        p = subprocess.Popen(cmd,
                             stdout=subprocess.PIPE,
                             stderr=subprocess.PIPE,
                             shell=True)
        stderr = p.communicate()[1].decode('utf-8')
    except Exception as e:
        print('Execution failed: %s' % e)
        success = False

    if p and p.returncode != 0:
        print('Execution failed, none zero code returned. \nSTDERR: %s' % repr(stderr), file=sys.stderr)
        success = False

    if not success:
        sys.exit(p.returncode if p.returncode else 1)

    return


def filename2file(upload_files):
    filename_to_file = {}
    for f in upload_files:
      filename_to_file[os.path.basename(f)] = f

    return filename_to_file


def main():
    parser = argparse.ArgumentParser(description='Tool: s3-upload')
    parser.add_argument("-s", dest="endpoint_url")
    parser.add_argument("-b", dest="bucket_name")
    parser.add_argument("-p", dest="payload")
    parser.add_argument("-c", dest="access_key")
    parser.add_argument("-k", dest="secret_key")
    parser.add_argument("-f", dest="files_to_upload", type=str, nargs="+", required=True)
    args = parser.parse_args()

    filename_to_file = filename2file(args.files_to_upload)

    with open(args.payload) as f:
      payload = json.load(f)

    if payload.get('analysisId'):
      analysisId = payload['analysisId']
    else:
      analysisId = 'analysisId'

    tumour_or_normal = payload['samples'][0]['specimen']['tumourNormalDesignation'].lower()

    analysisType = payload['analysisType']['name']

    path_prefix = "benchmark-datasets/%s/%s/%s/%s" % (
                                                payload['studyId'],
                                                payload['experiment']['experimental_strategy'],
                                                analysisType,
                                                tumour_or_normal
                                            )

    for object in payload['files']:
      filename = object['fileName']
      object_key = "%s/%s" % (path_prefix, filename)

      if filename in filename_to_file:
        file_to_upload = filename_to_file[filename]
      else:
        sys.exit(f"The filenames {filename} defined in the payload does not match what's in the inputs : {args.upload_files}")

      run_cmd('AWS_ACCESS_KEY_ID=%s AWS_SECRET_ACCESS_KEY=%s s5cmd --endpoint-url %s cp %s s3://%s/%s' % (
              args.access_key,
              args.secret_key,
              args.endpoint_url,
              file_to_upload,
              args.bucket_name,
              object_key))

    payload_object_key = "%s/%s.%s.json" % (path_prefix, analysisId, analysisType)
    run_cmd('AWS_ACCESS_KEY_ID=%s AWS_SECRET_ACCESS_KEY=%s s5cmd --endpoint-url %s cp %s s3://%s/%s' % (
        args.access_key,
        args.secret_key,
        args.endpoint_url,
        args.payload,
        args.bucket_name,
        payload_object_key))


if __name__ == "__main__":
  main()
