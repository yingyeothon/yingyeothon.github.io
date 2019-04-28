#!/bin/bash

if [ -z "${GIF2WEBP}" ]; then
  GIF2WEBP="gif2webp"
fi

SOURCE="$1"

if [ -z "${SOURCE}" ]; then
  echo "$0 [input-gif-file]"
  exit 0
fi

echo "${SOURCE}" | grep -E ".gif$" > /dev/null
if [ $? -ne 0 ]; then
  echo "Error: Input file should be gif file."
  echo "$0 [input-gif-file]"
  exit 1
fi

pushd "$(dirname "${SOURCE}")" > /dev/null

INPUT="$(basename "${SOURCE}")"
OUTPUT="$(basename "${SOURCE}" ".gif").webp"

echo "[$(date)] ${INPUT} > ${OUTPUT}"
"${GIF2WEBP}" "${INPUT}" -lossy -m 6 -f 50 -mt -o "${OUTPUT}"
echo "[$(date)] ${OUTPUT} completed."

popd > /dev/null

