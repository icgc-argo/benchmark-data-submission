#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
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
"""

import os
import sys
import argparse
import uuid
import json

def pop_sids(payload):
    with open(payload, 'r') as p:
        payload_dict = json.load(p)

    if 'samples' not in payload_dict:
        sys.exit("No 'samples' found in the payload.")

    # rm analysisState
    payload_dict.pop('analysisState', None)
    payload_dict.pop('analysisId', None)
    payload_dict['analysisType'].pop('version', None)
  
    # rm analysisPublish related
    for item in ['createdAt', 'createdAt', 'firstPublishedAt', 'publishedAt', 'analysisStateHistory', 'updatedAt']:
      payload_dict.pop(item, None)

    # rm sampleId, specimenId, donorId
    for sa in payload_dict['samples']:
      sa.pop('sampleId', None)
      sa.pop('specimenId', None)
      sa['specimen'].pop('specimenId', None)
      sa['specimen'].pop('donorId', None)
      sa['donor'].pop('donorId', None)
      sa['donor'].pop('studyId', None)

    # rm file.objectId, file.studyId, file.analysisId
    for f in payload_dict['files']:
        f.pop('objectId', None)
        f.pop('studyId', None)
        f.pop('analysisId', None)

    return payload_dict


def main():
    """
    Python implementation of tool: pop-system-ids

    This is auto-generated Python code, please update as needed!
    """

    parser = argparse.ArgumentParser(description='Tool: pop-system-ids')
    parser.add_argument('-p', '--payload', type=str, help='SONG metadata payload', required=True)
    args = parser.parse_args()

    if not os.path.isfile(args.payload):
      sys.exit('Error: specified payload file %s does not exist or is not accessible!' % args.payload)

    refreshed_payload = pop_sids(args.payload)

    with open("%s.payload.json" % str(uuid.uuid4()), 'w') as f:
      f.write(json.dumps(refreshed_payload, indent=2))

if __name__ == "__main__":
    main()

