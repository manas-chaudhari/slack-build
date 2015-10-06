#!/bin/sh

token=$1
channel=$2
build_id=$3

uploadFile() {
  comment_cmd=""
  if [[ ! -z "$2" ]]; then
    comment_cmd=" -F initial_comment=\"$2\""
  fi
  upload_cmd="curl -F file=@\"$1\" $comment_cmd -F channels=$channel -F token=$token https://slack.com/api/files.upload"
  eval $upload_cmd
}

# Build Command should place artifacts in `artifacts` directory
rm -rf artifacts
rm -rf build_log
git submodule update --init --recursive
./scripts/build.sh > build_log 2>&1
build_status=$?
artifact=`ls -1 artifacts | head -n 1`

if [[ -z "$artifact" ]] || [ $build_status != 0 ]; then
  uploadFile "build_log" "Build failed. Attaching log"
  exit 1
fi

# Upload archive to slack
uploadFile "artifacts/$artifact" "Build id: $build_id"
exit 0
