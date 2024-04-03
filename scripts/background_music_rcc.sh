#!/bin/bash
#
# background_music_rcc.sh
#
# Copyright (C) 2024 Timothée Giet
#
# Generate backgroundMusic rcc files for ogg, mp3 and aac.
# Must be started from the global main_generate_rcc.sh script.
#
# By default, generate backgroundMusic rcc only if there's a new commit since last time.
# Use the "force" argument to force generating all.
# In any case, encode files to prepare generating full rcc files.
#

if [ -z ${MAIN_SCRIPT+x} ]; then
  echo "This script must be started from the global main_generate_rcc.sh script."
  exit 1
fi

# Get last commit timestamp
LAST_MUSIC_COMMIT=$(git log -n 1 --pretty=format:%cd --date=format:"%Y-%m-%d-%H-%M-%S" ${DATA_SOURCE_DIR}/background-music/backgroundMusic)
echo "Last backgroundMusic commit date: "${LAST_MUSIC_COMMIT}

GENERATE_SINGLE_RCC=true

# Check if there is a new commit or option force used, else nothing to do
if grep -q -- "$LAST_MUSIC_COMMIT" "$OLD_MUSIC_CONTENTS" && [[ "$1" != "force" ]]; then
    GENERATE_SINGLE_RCC=false
    echo "Background music already up-to-date, will not generate single rcc."
fi

# Prepare folders
if [ "$GENERATE_SINGLE_RCC" = true ]; then
  mkdir ${DATA_DEST_DIR}/backgroundMusic
fi

mkdir ${DATA_BUILD_DIR}/backgroundMusic
cd ${DATA_BUILD_DIR}/backgroundMusic

function generate_codec_rcc {
    CODEC=$1
    mkdir ${CODEC}

    if [[ "$CODEC" == "ogg" ]]; then
        ln -s -r ${DATA_SOURCE_DIR}/background-music/backgroundMusic/ ogg/backgroundMusic
    else
        mkdir ${CODEC}/backgroundMusic
        cd ogg/
        $ENCODE_TO $CODEC backgroundMusic/ ${PWD}/../${CODEC}
        cd ..
    fi

    # link music folder for full-rcc generation
    ln -s -r ${CODEC}/backgroundMusic ${DATA_BUILD_DIR}/full-${CODEC}/backgroundMusic

    cd $CODEC
    QRC_MUSIC_CODEC=${PWD}/backgroundMusic-${CODEC}.qrc
    QRC_FULL_CODEC=${DATA_BUILD_DIR}/full-${CODEC}/full-${CODEC}.qrc
    header_qrc $QRC_MUSIC_CODEC
    for i in `find backgroundMusic/ -not -type d -name "*.${CODEC}" | sort | cut -c 1-`
    do
        echo "    <file>${i}</file>" >> $QRC_MUSIC_CODEC
        echo "    <file>${i}</file>" >> $QRC_FULL_CODEC
    done
    footer_qrc $QRC_MUSIC_CODEC

    if [ "$GENERATE_SINGLE_RCC" = true ]; then
      RCC_MUSIC_CODEC=${DATA_DEST_DIR}/backgroundMusic/backgroundMusic-${CODEC}-${LAST_MUSIC_COMMIT}.rcc
      $GENERATE_RCC $QRC_MUSIC_CODEC $RCC_MUSIC_CODEC
    fi

    cd ..
}

for CODEC in $CODEC_LIST
do
  generate_codec_rcc $CODEC
done

if [ "$GENERATE_SINGLE_RCC" = true ]; then
  # move to data3/backgroundMusic and generate Contents with checksums
  cd ${DATA_DEST_DIR}/backgroundMusic
  md5sum *.rcc > Contents
  cp Contents Contents-${CURRENT_DATE}
fi

cd $SCRIPT_DIR
