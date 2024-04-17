#!/bin/bash
#
# main_generate_rcc.sh
#
# Copyright (C) 2024 Timothée Giet
#
# Generate all rcc files for music, voices and words.
# Must be started from the scripts directory.
#
# By default, generate separate rcc files only if there's a new commit since last time.
# Use the "force" argument to force generating all.
# Encode all files to prepare generating full rcc files if there's any new commit,
# or use the "skipFullRcc" argument to skip full rcc build and encode only required files
# ("force" and "skipFullRcc" arguments are mutually exclusive, you can only use one of them).
#

# Export global variables

export SCRIPT_DIR=${PWD}
export DATA_SOURCE_DIR=${PWD}/..
export GENERATE_RCC=${PWD}/generate_rcc.sh
export ENCODE_TO=${PWD}/encode_to.sh
export MD5SUM=/usr/bin/md5sum
export MAIN_SCRIPT=true
export SERVER_PATH="https://cdn.kde.org/gcompris/data3"
export CODEC_LIST="ogg mp3 aac"
export BUILD_FULL_RCC=true

# the path depends on the distribution
export RCC=/usr/lib64/qt5/bin/rcc
#export RCC=/usr/bin/rcc

if [[ ! -f "${RCC}" ]] || [[ ! -x "${RCC}" ]]; then
  echo "rcc command path invalid. Change the RCC path in the script."
  exit 1
fi

export CURRENT_DATE=$(date "+%F-%H-%M-%S")

BACKGROUND_MUSIC_RCC=${PWD}/background_music_rcc.sh
VOICES_RCC=${PWD}/voices_rcc.sh
WORDS_RCC=${PWD}/words_rcc.sh

# Get last global commit timestamp
LAST_GLOBAL_COMMIT=$(git log -n 1 --pretty=format:%cd --date=format:"%Y-%m-%d-%H-%M-%S")
echo "Last global commit date: "${LAST_GLOBAL_COMMIT}

# Get current Contents files on the server
if [ -d "data-old-contents" ]; then
  rm -Rf data-old-contents
fi
mkdir data-old-contents
wget -q ${SERVER_PATH}/Contents -O data-old-contents/ContentsFull
OLD_FULL_CONTENTS="${PWD}/data-old-contents/ContentsFull"
wget -q ${SERVER_PATH}/backgroundMusic/Contents -O data-old-contents/ContentsMusic
export OLD_MUSIC_CONTENTS="${PWD}/data-old-contents/ContentsMusic"
wget -q ${SERVER_PATH}/voices-ogg/Contents -O data-old-contents/ContentsVoices
export OLD_VOICES_CONTENTS="${PWD}/data-old-contents/ContentsVoices"
wget -q ${SERVER_PATH}/words/Contents -O data-old-contents/ContentsWords
export OLD_WORDS_CONTENTS="${PWD}/data-old-contents/ContentsWords"

# Check if there is a new commit or option force used, else nothing to do
if grep -q -- "$LAST_GLOBAL_COMMIT" "$OLD_FULL_CONTENTS" && [[ "$1" != "force" ]]; then
  echo "No new commit since last Full RCC generation, nothing to do. Use force option to generate anyway."
  exit 0
fi

# If option skipFullRcc used, disable full rcc build
if [[ "$1" == "skipFullRcc" ]]; then
  BUILD_FULL_RCC=false
fi

# Functions to generate qrc files header and footer
function header_qrc {
(cat <<EOHEADER
<!DOCTYPE RCC><RCC version="1.0">
<qresource prefix="/gcompris/data">
EOHEADER
) > $1
}

export -f header_qrc

function footer_qrc {
(cat <<EOFOOTER
</qresource>
</RCC>
EOFOOTER
) >> $1
}

export -f footer_qrc

# Prepare global folders
# folder for final rcc path
if [ -d "data3" ]; then
  rm -Rf data3
fi
mkdir data3
export DATA_DEST_DIR=${SCRIPT_DIR}/data3

# folder for temporary file manipulation
if [ -d "data-build" ]; then
  rm -Rf data-build
fi
mkdir data-build
export DATA_BUILD_DIR=${SCRIPT_DIR}/data-build

# folders and qrc for full rcc files
for CODEC in $CODEC_LIST
do
  mkdir ${DATA_BUILD_DIR}/full-${CODEC}
  QRC_FULL_CODEC=${DATA_BUILD_DIR}/full-${CODEC}/full-${CODEC}.qrc
  header_qrc $QRC_FULL_CODEC
done

# Run those 3 scripts in this exact order: music, voices and words.
$BACKGROUND_MUSIC_RCC $1
$VOICES_RCC $1
$WORDS_RCC $1

if [[ $BUILD_FULL_RCC == true ]]; then
  for CODEC in $CODEC_LIST
  do
    QRC_FULL_CODEC=${DATA_BUILD_DIR}/full-${CODEC}/full-${CODEC}.qrc
    footer_qrc $QRC_FULL_CODEC
    RCC_FULL_CODEC=${DATA_DEST_DIR}/full-${CODEC}-${LAST_GLOBAL_COMMIT}.rcc
    $GENERATE_RCC $QRC_FULL_CODEC $RCC_FULL_CODEC
  done

  cd ${DATA_DEST_DIR}
  md5sum full-*.rcc > Contents
  cp Contents Contents-${CURRENT_DATE}
fi

cd ${SCRIPT_DIR}
