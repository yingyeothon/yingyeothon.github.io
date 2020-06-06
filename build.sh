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
