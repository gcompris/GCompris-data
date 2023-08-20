#!/bin/bash
#
# generate_backgroundMusic_rcc.sh

# Copyright (C) 2014 Holger Kaelberer
# Copyright (C) 2016 Divyam Madaan
#
# Generates Qt binary resource files (.rcc) for background music.
#
# Results will be written to $PWD/.rcc/ which is supposed be synced to the
# upstream location.
#

# the path depends on the distribution
#export RCC=/usr/lib64/qt5/bin/rcc
export RCC=/usr/bin/rcc

[ $# -ne 1 ] && {
    echo "Usage: generate_backgroundMusic_rcc.sh ogg|aac|ac3|mp3"
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
QRC_FULL_FILE="${QRC_DIR}/backgroundMusic-${CA}.qrc"
RCC_FULL_FILE="${RCC_DIR}/backgroundMusic-${CA}-${LAST_UPDATE_DATE}.rcc"
header_rcc $QRC_FULL_FILE

for i in `find backgroundMusic -type f -name "*.$CA" | sort | cut -c 1-`
do
	echo "    <file>${i#${MUSIC_DIR}}</file>" >> "${QRC_DIR}/backgroundMusic-${CA}.qrc"
done
footer_rcc $QRC_FULL_FILE
echo -n "  full: ${QRC_FULL_FILE} ... "
generate_rcc ${QRC_FULL_FILE} ${RCC_FULL_FILE}

echo "Finished!"
echo ""

#EOF


