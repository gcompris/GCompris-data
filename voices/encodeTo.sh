#!/bin/sh

# First create a new directory (aac ac3 mp3)
# Example for aac:
# rsync -a --exclude .git voices.ogg/ voices.aac
# cd voices.aac
# ./encodeTo.sh

if [ $# -ne 1 ]
then
  echo "Usage $(basename $0) aac|ac3|mp3"
  exit 1
fi

if [ ! -d af ]
then
  echo "ERROR: move to the voice directory first"
  exit 1
fi

format=$1

encoder="avconv"
if command -v avconv >/dev/null 2>&1;
then
    echo "avconv found"
    if [ $format = "aac" ]
    then
        codec="libvo_aacenc"
    elif [ $format = "ac3" ]
    then
        codec="ac3"
    elif [ $format = "mp3" ]
    then
        codec="libmp3lame"
    else
        echo "Error, unsupported format $1"
        exit 1
    fi
elif command -v ffmpeg >/dev/null 2>&1;
then
    echo "ffmpeg found"
    encoder="ffmpeg"
    if [ $format = "aac" ]
    then
        codec="aac"
    elif [ $format = "ac3" ]
    then
        codec="ac3"
    elif [ $format = "mp3" ]
    then
        codec="mp3"
    else
        echo "Error, unsupported format $1"
        exit 1
    fi
else
    echo "neither avconv nor ffmpeg found"
    exit 1
fi

task() {
    #echo "Processing $1"
    $encoder -v warning -i $1 -acodec $codec ${1%.*}.${format} </dev/null > /dev/null 2>&1
    if [ $? -ne 0 ]
    then
       echo "ERROR: Failed to convert $f"
    fi
    rm -f $1
}

parallelCount=4
echo "Transcode ogg files to $format"
start=$SECONDS
for f in $(find . -type f -name \*.ogg)
do
    ((i=i%parallelCount)); ((i++==0)) && wait
    task $f &
done
duration=$(( SECONDS - start ))
echo "Conversion took $duration seconds"

echo "Fix symlinks"
start=$SECONDS
for f in $(find . -type l -name \*.ogg)
do
    #echo "Processing $f"
    target=$(readlink -f $f)
    rm $f
    ln -s -r ${target%.*}.${format} ${f%.*}.${format}
done
duration=$(( SECONDS - start ))
echo "Fix symlinks took $duration seconds"

