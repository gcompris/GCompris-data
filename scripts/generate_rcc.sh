#!/bin/bash
#
# generate_rcc.sh
#
# Copyright (C) 2024 Timothée Giet
#
# General script to generate rcc files.
# Requires 2 arguments:
#   - input qrc file
#   - output rcc file path
#

if [[ $# -ne 2 ]]; then
  echo "The script to generate rcc requires exactly 2 arguments"
  exit 2
fi

echo "Generate "$(basename ${2})" from "$(basename ${1})

# We need to use --format-version 2 option for rcc to be retro-compatible with all our GCompris versions
${RCC} --format-version 2 --binary $1 -o $2

exit 0


