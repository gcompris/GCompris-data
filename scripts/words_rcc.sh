#!/bin/bash
#
# words_rcc.sh
#
# Copyright (C) 2024 Timothée Giet
#
# Generate words-webp rcc files.
# Must be started from the global main_generate_rcc.sh script.
#
# By default, generate words-webp rcc only if there's a new commit since last time.
# Use the "force" argument to force generating all.
# In any case, prepare generating full rcc files,
# except if using the "skipFullRcc" argument.
# ("force" and "skipFullRcc" arguments are mutually exclusive, you can only use one of them).
#

if [ -z ${MAIN_SCRIPT+x} ]; then
  echo "This script must be started from the global main_generate_rcc.sh script."
  exit 1
fi

# Get last commit timestamp
LAST_WORDS_COMMIT=$(git log -n 1 --pretty=format:%cd --date=format:"%Y-%m-%d-%H-%M-%S" ../words/words-webp)
echo "Last words commit date: "${LAST_WORDS_COMMIT}

GENERATE_SINGLE_RCC=true

# Check if there is a new commit or option force used, else nothing to do
if grep -q -- "$LAST_WORDS_COMMIT" "$OLD_WORDS_CONTENTS" && [[ "$1" != "force" ]]; then
    GENERATE_SINGLE_RCC=false
    echo "Words already up-to-date, will not generate single rcc."
fi

# If no single rcc to generate and full rcc skipped, nothing else to do
if [[ $GENERATE_SINGLE_RCC == false ]] && [[ $BUILD_FULL_RCC == false ]]; then
  cd $SCRIPT_DIR
  exit 0
fi

# Prepare folders
if [ "$GENERATE_SINGLE_RCC" = true ]; then
  mkdir ${DATA_DEST_DIR}/words
fi

mkdir ${DATA_BUILD_DIR}/words
cd ${DATA_BUILD_DIR}/words

function generate_words_rcc {
    FORMAT=$1

    ln -s -r ${DATA_SOURCE_DIR}/words/words-${FORMAT} words-${FORMAT}
    # link words folder for full-rcc generation
    for CODEC in ${CODEC_LIST}
    do
        ln -s -r words-${FORMAT} ${DATA_BUILD_DIR}/full-${CODEC}/words-${FORMAT}
    done

    QRC_WORDS=${PWD}/words-${FORMAT}.qrc
    QRC_FULL_TMP=${PWD}/full-tmp.qrc
    header_qrc $QRC_WORDS
    for i in `find words-${FORMAT}/ -not -type d -name "*.${FORMAT}" -o -name "*.svg" | sort | cut -c 1-`
    do
        echo "    <file>${i}</file>" >> $QRC_WORDS
        echo "    <file>${i}</file>" >> $QRC_FULL_TMP
    done
    footer_qrc $QRC_WORDS

    for CODEC in ${CODEC_LIST}
    do
        QRC_FULL_CODEC=${DATA_BUILD_DIR}/full-${CODEC}/full-${CODEC}.qrc
        cat "${QRC_FULL_TMP}" >> ${QRC_FULL_CODEC}
    done

    rm $QRC_FULL_TMP

    if [ "$GENERATE_SINGLE_RCC" = true ]; then
      RCC_WORDS=${DATA_DEST_DIR}/words/words-${FORMAT}-${LAST_WORDS_COMMIT}.rcc
      $GENERATE_RCC $QRC_WORDS $RCC_WORDS
    fi
}

generate_words_rcc webp

if [ "$GENERATE_SINGLE_RCC" = true ]; then
  # move to data3/words and generate Contents with checksums
  cd ${DATA_DEST_DIR}/words
  md5sum *.rcc > Contents
  cp Contents Contents-${CURRENT_DATE}
fi

cd $SCRIPT_DIR
