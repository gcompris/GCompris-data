#!/bin/bash
#
# clean_all.sh
#
# Copyright (C) 2024 Timothée Giet
#

echo "Cleaning build directory"
rm -Rf data-build
echo "Cleaning old contents"
rm -Rf data-old-contents
echo "Cleaning rcc files"
rm -Rf data3
