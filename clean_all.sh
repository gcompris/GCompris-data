#!/bin/bash
#
# clean_all.sh
#
# Copyright (C) 2017 Johnny Jazeix
#

echo "Cleaning background music"
cd background-music
rm -rf .rcc aac ogg mp3
echo "Cleaning voices"
cd ../voices
rm -rf aac ogg mp3
