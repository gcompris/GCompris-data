#!/bin/bash
#
# Run this script on gcompris.net to update the rcc files
# being served by it.
#
# cd /opt/gcompris
# ./updateVoices.sh
#

# the path depends on the distribution
# export RCC=/usr/lib64/qt5/bin/rcc
export RCC=/usr/bin/rcc

echo "Generate ogg rcc"
rm -rf ogg
rsync -a --exclude .git --exclude aac --exclude mp3 . ogg
cd ogg
./generate_voices_rcc.sh ogg
cd ../

function generateEncodedVoices {
    codec=$1
    echo "Create the $codec directory"
    rm -rf $codec
    rsync -a --exclude .git --exclude voices-ogg ogg/ $codec
    cd $codec

    echo "Encoding $codec files"
    ./encodeTo.sh $codec

    echo "Generate $codec rcc"
    ./generate_voices_rcc.sh $codec

    echo "Consolidate the top level Content file"
    cat .rcc/Contents >> ../ogg/.rcc/Contents
    rm .rcc/Contents

#    echo "Update $codec on gcompris.net"
#    rsync -avx .rcc/ /var/www/data2/
    cd ..
}

generateEncodedVoices aac
generateEncodedVoices mp3

#echo "Update ogg on gcompris.net"
#cd ogg
#rsync -avx .rcc/ /var/www/data2/
