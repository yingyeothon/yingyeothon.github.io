#!/bin/bash

SYNC_LOG="$(mktemp)"
TARGET_PATHS_LOG="$(mktemp)"

rm -rf _site/ && \
  aws s3 sync s3://yyt.life _site/
if [ $? -ne 0 ]; then
  echo "Sync down is failed."
  exit 1
fi

jekyll build --future
if [ $? -ne 0 ]; then
  echo "Failed to build."
  exit 1
fi

aws s3 sync _site/ s3://yyt.life \
  | grep "upload:" \
  | tee "${SYNC_LOG}"
if [ $? -ne 0 ]; then
  echo "Sync up is failed."
  exit 1
fi

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
if [ -z "${DISTRIBUTION_ID}" ]; then
  echo "Distribution id is empty."
  exit 1;
fi

aws cloudfront create-invalidation \
  --distribution-id "${DISTRIBUTION_ID}" \
  --paths ${TARGET_PATHS}
if [ $? -ne 0 ]; then
  echo "Cache invalidation is failed."
  exit 1
if

rm -f "${SYNC_LOG}" "${TARGET_PATHS_LOG}"

