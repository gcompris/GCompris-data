#!/bin/bash
#
# generate_all_rcc.sh
#
# Copyright (C) 2017 Johnny Jazeix
#
# Generates Qt binary resource files (.rcc) for lang images
#
# Usage:
# cd git/src/lang-activity/resources/lang
# generate_lang_rcc.sh
#
# Results will be written to $PWD/.rcc/ which is supposed be synced to the
# upstream location.
#

echo "Building background music"
cd background-music
./update_backgroundMusic.sh
echo "Building voices"
cd ../voices
./update_voices.sh
#echo "Building words"
#cd ../words
#./generate_lang_rcc.sh
