#!/bin/bash

set -u
set -e

TARGET_STRING=$1
NEW_STRING=$2

FILE="./_config.yaml"
TMP_FILE="_config.yaml.tmp"

sed s/${TARGET_STRING}/${NEW_STRING}/ ${FILE} > ${TMP_FILE}
mv ${TMP_FILE} ${FILE}
