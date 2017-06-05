#!/bin/bash
#
# Run this script on gcompris.net to update the rcc files
# being served by it.
#
# cd /opt/gcompris
# ./update_backgroundMusic.sh
#

function generateEncodedVoices {
    codec=$1
    echo "Create the $codec directory"
    rm -rf $codec

    rsync -a --exclude .git backgroundMusic *.sh $codec
    cd $codec

    if [[ $codec != ogg ]]; then
        echo "Encoding $codec files"
        ./encodeTo.sh $codec
    fi
    
    echo "Generate $codec rcc"
    ./generate_backgroundMusic_rcc.sh $codec

    if [[ $codec != ogg ]]; then
        echo "Consolidate the top level Content file"
        cat .rcc/Contents >> ../ogg/.rcc/Contents
        mv .rcc/backgroundMusic-$codec.rcc ../ogg/.rcc/
        rm -rf .rcc
    fi

    cd ..
}

generateEncodedVoices ogg
generateEncodedVoices aac
generateEncodedVoices mp3

mv ogg/.rcc .rcc

#echo "Update ogg on gcompris.net"
#rsync -avx .rcc/ /var/www/data2/backgroundMusic/
