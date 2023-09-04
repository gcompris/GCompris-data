#!/bin/bash
#
# generate_voices_rcc.sh
#
# Copyright (C) 2014 Holger Kaelberer
#
# Generates Qt binary resource files (.rcc) for voices locales.
#
# Results will be written to $PWD/.rcc/ which is supposed be synced to the
# upstream location.
#

[ $# -ne 1 ] && {
    echo "Usage: generate_voices_rcc.sh ogg|aac|ac3|mp3"
    exit 1
}

# Compressed Audio Format
CA=$1

QRC_DIR="."
RCC_DIR=".rcc"
#RCC_DEFAULT=`which rcc 2>/dev/null`   # default, better take /usr/bin/rcc?
RCC_DEFAULT=$Qt5_DIR/bin/rcc
CONTENTS_FILE=Contents
MD5SUM=/usr/bin/md5sum

[ -z "${RCC}" ] && RCC=${RCC_DEFAULT}

[ -z "${RCC}" ] && {
    echo "No rcc command in PATH, can't continue. Try to set specify RCC in environment:"
    echo "RCC=/path/to/qt/bin/rcc $0"
    exit 1
}

WORDS_NAME=words-webp
WORDS_DIR=../../words/${WORDS_NAME}
[ ! -d "${WORDS_DIR}" ] && {
    echo "Words dir ${WORDS_DIR} not found"
    exit 1
}
[ -d ${WORDS_NAME} ] && rm -rf ${WORDS_NAME}
ln -s ${WORDS_DIR} ${WORDS_NAME}

# Duplicate for old words (in png, not webp)
OLD_WORDS_NAME=words
OLD_WORDS_DIR=../../words/${OLD_WORDS_NAME}
[ ! -d "${OLD_WORDS_DIR}" ] && {
    echo "Words dir ${OLD_WORDS_DIR} not found"
    exit 1
}
[ -d ${OLD_WORDS_NAME} ] && rm -rf ${OLD_WORDS_NAME}
ln -s ${OLD_WORDS_DIR} ${OLD_WORDS_NAME}

# We need to use --format-version 2 option for rcc to be retro-compatible with all our GCompris versions
function generate_rcc {
    # Generate RCC 
    echo -n "$2 ... "
    mkdir -p ${2%/*}
    ${RCC} --format-version 2 --binary $1 -o $2

    echo "md5sum ... "
    cd ${2%/*}
    ${MD5SUM}  ${2##*/}>> ${CONTENTS_FILE}
    cd - &>/dev/null
}

function generate_words_rcc {
    header_rcc "${QRC_DIR}/$1.qrc"
    for i in `find $1/ -not -type d | sort`; do
	echo "    <file>${i#${2}}</file>" >> "${QRC_DIR}/$1.qrc"
    done
    footer_rcc "${QRC_DIR}/$1.qrc"
    echo -n "  $1: "${QRC_DIR}/$1.qrc" ... "
    generate_rcc "${QRC_DIR}/$1.qrc" "${RCC_DIR}/words/$1.rcc"
}

function header_rcc {
(cat <<EOHEADER
<!DOCTYPE RCC><RCC version="1.0">
<qresource prefix="/gcompris/data">
EOHEADER
) > $1
}

function footer_rcc {
(cat <<EOFOOTER
</qresource>
</RCC>
EOFOOTER
) >> $1
}

echo "Generating binary resource files in ${RCC_DIR}/ folder:"

[ -d ${RCC_DIR} ] && rm -rf ${RCC_DIR}
mkdir  ${RCC_DIR}

#header of the global qrc (all the langs)
QRC_FULL_FILE="${QRC_DIR}/full-${CA}.qrc"
RCC_FULL_FILE="${RCC_DIR}/full-${CA}.rcc"
header_rcc $QRC_FULL_FILE

# Create the voices directory that will contains links to locales dir
VOICE_DIR="voices-${CA}"
[ -d ${RCC_DIR} ] && rm -rf ${RCC_DIR}
rm -rf ${VOICE_DIR}
mkdir -p ${VOICE_DIR}

for LANG in `find . -maxdepth 1 -regextype posix-egrep -type d -regex "\./[a-z]{2,3}(_[A-Z]{2,3})?" -follow | sort`; do
    QRC_FILE="${QRC_DIR}/voices-${LANG#./}.qrc"
    RCC_FILE="${RCC_DIR}/${VOICE_DIR}/voices-${LANG#./}.rcc"

    # Populate the voices backlinks
    ln -s -t ${VOICE_DIR} ../$LANG

    # Generate QRC:
    echo -n "  ${LANG#./}: ${QRC_FILE} ... "
    # check for junk in the voices dirs:
    if [[ -d .git && ! -z "`git status --porcelain ${LANG} | grep '^??'`" ]]; then
        echo "Warning, found untracked files in your git checkout below ${LANG}. Better "git clean -f" it first!";
    fi
    [ -e ${QRC_FILE} ] && rm ${QRC_FILE}

    header_rcc $QRC_FILE
    for i in `find ${LANG}/ -not -type d | sort`; do
	# For the lang file
        echo "    <file>${VOICE_DIR}/${i#./}</file>" >> $QRC_FILE
	# For the all lang file
        echo "    <file>${VOICE_DIR}/${i#./}</file>" >> $QRC_FULL_FILE
    done
    footer_rcc $QRC_FILE
    generate_rcc ${QRC_FILE} ${RCC_FILE}

done

# Word images for the full qrc
for i in `find ${WORDS_NAME}/ -not -type d | sort`; do
    echo "    <file>${i#${WORDS_DIR}}</file>" >> $QRC_FULL_FILE
done

#footer of the global qrc (all the langs)
footer_rcc $QRC_FULL_FILE

echo -n "  full: ${QRC_FULL_FILE} ... "
generate_rcc ${QRC_FULL_FILE} ${RCC_FULL_FILE}

# Word images standalone rcc
# This is generated only when the script is called to generate ogg files
# as this is our reference and images does not depends on the audio codec
if [[ $CA == ogg ]]
then
    generate_words_rcc ${WORDS_NAME} ${WORDS_DIR}
    generate_words_rcc ${OLD_WORDS_NAME} ${OLD_WORDS_DIR}
fi

#cleanup:
#rm -f *.qrc
#rm ${WORDS_NAME}
#rm -rf ${VOICE_DIR}

echo "Finished!"
echo ""
echo "Consolidate .rcc/Contents in a master ${RCC_DIR}"
echo "containing all the encoded content."
echo ""
echo "Then do something like:"
echo "rsync -avx ${RCC_DIR}/  gcompris.net:/var/www/data2/"
#EOF
