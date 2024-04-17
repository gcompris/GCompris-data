#!/bin/sh
#
# encode_to.sh
#
# Copyright (C) 2024 Timothée Giet
#
# General script to encode audio files to mp3 or acc.
# Requires 3 arguments:
#   - format (mp3 or aac)
#   - input relative directory path
#   - output absolute directory path.
#

if [[ $# -ne 3 ]]; then
  echo "The script to encode audio requires exactly 3 arguments"
  exit 2
fi

FORMAT=$1

ENCODER="avconv"
if command -v avconv >/dev/null 2>&1; then
  echo "avconv found"
  if [ $FORMAT = "aac" ]; then
    CODEC="libvo_aacenc"
  elif [ $FORMAT = "mp3" ]; then
    CODEC="libmp3lame"
  else
    echo "Error, unsupported FORMAT $1"
    exit 1
  fi
elif command -v ffmpeg >/dev/null 2>&1; then
  echo "ffmpeg found"
  ENCODER="ffmpeg"
  if [ $FORMAT = "aac" ]; then
    CODEC="aac"
  elif [ $FORMAT = "mp3" ]; then
    CODEC="mp3"
  else
    echo "Error, unsupported FORMAT $1"
    exit 1
  fi
else
  echo "neither avconv nor ffmpeg found"
  exit 1
fi

echo "Transcode ogg files to $FORMAT"
for f in $(find $2 -type f -name \*.ogg)
do
  OUTPUT_FILE=${3}/${f%.*}.${FORMAT}
  $ENCODER -v warning -i $f -acodec $CODEC $OUTPUT_FILE
  if [ $? -ne 0 ]
  then
    echo "ERROR: Failed to convert $f"
  fi
  id3v2 -a "$(vorbiscomment --list $f | grep 'ARTIST' | cut -d '=' -f 2)" $OUTPUT_FILE
  id3v2 -t "$(vorbiscomment --list $f | grep 'TITLE' | cut -d '=' -f 2)" $OUTPUT_FILE
  id3v2 -y "$(vorbiscomment --list $f | grep 'DATE' | cut -d '=' -f 2)" $OUTPUT_FILE
  id3v2 --TCOP "$(vorbiscomment --list $f | grep 'COPYRIGHT' | cut -d '=' -f 2)" $OUTPUT_FILE
done

echo "Fix symlinks"
# NOTE: symlinks are supported only if they are in the same directory as the file they point to.
for f in $(find $2 -type l -name \*.ogg)
do
  TARGET=$(readlink -f $f)
  TARGET_BASENAME=$(basename "${TARGET%.*}")
  ln -s ${TARGET_BASENAME}.${FORMAT} ${3}/${f%.*}.${FORMAT}
done
