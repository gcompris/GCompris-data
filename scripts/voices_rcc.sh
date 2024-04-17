#!/bin/bash
#
# voices_rcc.sh
#
# Copyright (C) 2024 Timothée Giet
#
# Generate voices rcc files for ogg, mp3 and aac.
# Must be started from the global main_generate_rcc.sh script.
#
# By default, generate a separate rcc for a language only if there's a new commit since last time.
# Use the "force" argument to force generating all.
# Encode all files to prepare generating full rcc files,
# or use the "skipFullRcc" argument to skip full rcc build and encode only required files
# ("force" and "skipFullRcc" arguments are mutually exclusive, you can only use one of them).
#

if [ -z ${MAIN_SCRIPT+x} ]; then
  echo "This script must be started from the global main_generate_rcc.sh script."
  exit 1
fi

# Prepare folders
mkdir ${DATA_BUILD_DIR}/voices
ln -s -r ${DATA_SOURCE_DIR}/voices ${DATA_BUILD_DIR}/voices/voices-ogg

cd ${DATA_BUILD_DIR}/voices/
VOICES_BASEDIR=${PWD}
cd voices-ogg

for CODEC in $CODEC_LIST
do
    # convert all voices to CODEC_LIST (except ogg)
    if [ $CODEC != "ogg" ]; then
        # create directory tree for each codec
        mkdir ${VOICES_BASEDIR}/voices-${CODEC}
        for DIRECTORY in `find . -mindepth 1 -type d -follow | sort`
        do
            mkdir ${VOICES_BASEDIR}/voices-${CODEC}/${DIRECTORY}
        done
        # check for each lang if voices need to be converted to $CODEC
        for LANG in `find . -mindepth 1 -maxdepth 1 -type d -follow | sort`
        do
            LANG_CODE=${LANG//.\//}
            OLD_CONTENTS_LINE=$(grep -- "-${LANG_CODE}-" "${OLD_VOICES_CONTENTS}")
            # !!! special case for "en" folder which is a link to "en_gb"
            if [[ $LANG_CODE == "en" ]]; then
                LAST_LANG_COMMIT=$(git log -n 1 --pretty=format:%cd --date=format:"%Y-%m-%d-%H-%M-%S" ${SCRIPT_DIR}/../voices/en_GB)
            else
                LAST_LANG_COMMIT=$(git log -n 1 --pretty=format:%cd --date=format:"%Y-%m-%d-%H-%M-%S" ${SCRIPT_DIR}/../voices/${LANG_CODE})
            fi
            if [[ "$OLD_CONTENTS_LINE" == *"$LAST_LANG_COMMIT"* ]] && [[ "$1" != "force" ]] && [[ $BUILD_FULL_RCC == false ]]; then
                echo "No need to convert voices to ${CODEC} for ${LANG_CODE}"
            else
                echo "Convert voices to ${CODEC} for ${LANG_CODE}"
                # !!! special case for "en" folder which is a link to "en_gb"
                if [[ $LANG_CODE != "en" ]]; then
                    $ENCODE_TO $CODEC $LANG ${VOICES_BASEDIR}/voices-${CODEC}
                else
                    echo "Special case for english symlink folder detected."
                fi
            fi
        done
        # !!! special case for "en" folder which is a link to "en_gb"
        rsync -a ${VOICES_BASEDIR}/voices-${CODEC}/en_GB/ ${VOICES_BASEDIR}/voices-${CODEC}/en/
    fi

    # link voices folders for full-rcc generation
    ln -s -r ${VOICES_BASEDIR}/voices-${CODEC} ${DATA_BUILD_DIR}/full-${CODEC}/voices-${CODEC}
    # qrc link for full-rcc generation
    QRC_FULL_CODEC=${DATA_BUILD_DIR}/full-${CODEC}/full-${CODEC}.qrc
    # destination path for separate rcc files
    mkdir ${DATA_DEST_DIR}/voices-${CODEC}
    NEW_CONTENTS=${DATA_DEST_DIR}/voices-${CODEC}/Contents
    # check for each lang if separate rcc needs to be generated (else copy old Contents line)
    for LANG in `find . -mindepth 1 -maxdepth 1 -type d -follow | sort`
    do
        LANG_CODE=${LANG//.\//}
        OLD_CONTENTS_LINE=$(grep -- "-${LANG_CODE}-" "${OLD_VOICES_CONTENTS}")
        # !!! special case for "en" folder which is a link to "en_gb"
        if [[ $LANG_CODE == "en" ]]; then
            LAST_LANG_COMMIT=$(git log -n 1 --pretty=format:%cd --date=format:"%Y-%m-%d-%H-%M-%S" ${SCRIPT_DIR}/../voices/en_GB)
        else
            LAST_LANG_COMMIT=$(git log -n 1 --pretty=format:%cd --date=format:"%Y-%m-%d-%H-%M-%S" ${SCRIPT_DIR}/../voices/${LANG_CODE})
        fi
        if [[ "$OLD_CONTENTS_LINE" == *"$LAST_LANG_COMMIT"* ]] && [[ "$1" != "force" ]]; then
            echo "No need to generate ${CODEC} voice rcc for ${LANG_CODE}"
            # copy checksum and filename from old Contents to new Contents
            echo "${OLD_CONTENTS_LINE}" >> ${NEW_CONTENTS}
            # populate only qrc for full rcc if full rcc build enabled
            if [[ $BUILD_FULL_RCC == true ]]; then
                for FILENAME in `find $LANG_CODE -not -type d -follow -name "*.ogg" | sort`
                do
                    echo "    <file>voices-${CODEC}/${FILENAME%.*}.${CODEC}</file>" >> $QRC_FULL_CODEC
                done
            fi
        else
            echo "Generating voices ${CODEC} rcc for "${LANG_CODE}
            QRC_VOICE_CODEC_LANG=$VOICES_BASEDIR/voices-${CODEC}-${LANG_CODE}.qrc
            header_qrc $QRC_VOICE_CODEC_LANG
            # populate qrc for separate and full rcc
            for FILENAME in `find $LANG_CODE -not -type d -follow -name "*.ogg" | sort`
            do
                echo "    <file>voices-${CODEC}/${FILENAME%.*}.${CODEC}</file>" >> $QRC_VOICE_CODEC_LANG
                if [[ $BUILD_FULL_RCC == true ]]; then
                    echo "    <file>voices-${CODEC}/${FILENAME%.*}.${CODEC}</file>" >> $QRC_FULL_CODEC
                fi
            done
            footer_qrc $QRC_VOICE_CODEC_LANG
            # generate separate rcc and add its checksum to Contents
            RCC_LANG_CODEC=${DATA_DEST_DIR}/voices-${CODEC}/voices-${LANG_CODE}-${LAST_LANG_COMMIT}.rcc
            $GENERATE_RCC $QRC_VOICE_CODEC_LANG $RCC_LANG_CODEC
            cd ${DATA_DEST_DIR}/voices-${CODEC}/
            md5sum $(basename "${RCC_LANG_CODEC}") >> $NEW_CONTENTS
            cd ${VOICES_BASEDIR}/voices-ogg
        fi
    done
    cd ${DATA_DEST_DIR}/voices-${CODEC}/
    cp Contents Contents-${CURRENT_DATE}
    cd ${VOICES_BASEDIR}/voices-ogg
done

cd $SCRIPT_DIR
