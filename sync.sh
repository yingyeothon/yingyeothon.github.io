#!/bin/bash

SYNC_LOG="$(mktemp)"
TARGET_PATHS_LOG="$(mktemp)"

jekyll build --future
aws s3 sync _site/ s3://yyt.life \
  | grep "upload:" \
  | tee "${SYNC_LOG}"

cat "${SYNC_LOG}" \
  | cut -d" " -f22 \
  | cut -d"/" -f4- \
  | sed -e 's/^/\//' \
  | sort -u \
  | grep -v "/KiB" \
  | tee "${TARGET_PATHS_LOG}"
TARGET_PATHS="$(cat "${TARGET_PATHS_LOG}")"

DISTRIBUTION_ID="$(aws cloudfront list-distributions \
  | jq -r '.DistributionList.Items[] | select(.Aliases.Items[0]=="www.yyt.life") | .Id' \
)"

aws cloudfront create-invalidation \
  --distribution-id "${DISTRIBUTION_ID}" \
  --paths ${TARGET_PATHS}

rm -f "${SYNC_LOG}" "${TARGET_PATHS_LOG}"

