#!/bin/bash

SYNC_LOG="$(mktemp)"
TARGET_PATHS_LOG="$(mktemp)"

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
  | egrep "(.html|.css|.jpg|.png|.js)" \
  | tee "${TARGET_PATHS_LOG}"
TARGET_PATHS="$(cat "${TARGET_PATHS_LOG}")"

DISTRIBUTION_ID="$(aws cloudfront list-distributions \
  | jq -r '.DistributionList.Items[] | select(.Aliases.Items[0]=="www.yyt.life") | .Id' \
)"
if [ -z "${DISTRIBUTION_ID}" ]; then
  echo "Distribution id is empty."
  exit 1
fi

aws cloudfront create-invalidation \
  --distribution-id "${DISTRIBUTION_ID}" \
  --paths ${TARGET_PATHS}

if [ $? -ne 0 ]; then
  echo "Cache invalidation is failed."
  exit 1
fi

rm -f "${SYNC_LOG}" "${TARGET_PATHS_LOG}"

