#!/bin/bash

SYNC_LOG="$(mktemp)"
TARGET_PATHS_LOG="$(mktemp)"
BUCKET_NAME="yyt-life-website"

jekyll build --future
if [ $? -ne 0 ]; then
  echo "Failed to build."
  exit 1
fi

# Optimize image resources
du -hcs _site
which convert
if [ $? -eq 0 ]; then
  for FILE in $(find _site -name *.jpg -o -name *.png); do
    file $FILE;
    convert $FILE -resize 1920x1920\> $FILE;
    file $FILE;
  done
fi
which pngquant
if [ $? -eq 0 ]; then
  pngquant --force --ext .png --verbose --quality 80-90 --strip --skip-if-larger $(find _site -type f -name "*.png")
fi
which jpegoptim
if [ $? -eq 0 ]; then
  jpegoptim -f -o -v -s -m95 $(find _site -type f -name "*.jpg")
fi
du -hcs _site

# Upload all things to S3
aws s3 sync --size-only --delete --no-progress _site/ "s3://${BUCKET_NAME}" \
  | tee "${SYNC_LOG}"
if [ $? -ne 0 ]; then
  echo "Sync up is failed."
  exit 1
fi

cat "${SYNC_LOG}" \
  | rev \
  | cut -d" " -f1 \
  | rev \
  | cut -d"/" -f4- \
  | grep -v '^$' \
  | sed -e 's/^/\//' \
  | sort -u \
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
  --paths ${TARGET_PATHS} "/"

if [ $? -ne 0 ]; then
  echo "Cache invalidation is failed."
  exit 1
fi

rm -f "${SYNC_LOG}" "${TARGET_PATHS_LOG}"

