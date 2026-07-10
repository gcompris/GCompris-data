#!/usr/bin/python
#
# GCompris - check_intro_differences.py
#
# Copyright (C) 2026 Johnny Jazeix <jazeix@gmail.com>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, see <https://www.gnu.org/licenses/>.
#
# Lists all audio files which do not correspond to an existing activity
#
import os
import sys

if len(sys.argv) < 2:
    print("Usage: check_intro_differences.py path_to_gcompris [lang]")
    sys.exit(1)

gcompris_qt = sys.argv[1]
langs = [] if len(sys.argv) < 3 else [sys.argv[2]]
current_dir = os.getcwd()

activities_path = os.path.join(gcompris_qt, "src", "activities")
activities_list = sorted([item for item in os.listdir(activities_path) if os.path.isdir(os.path.join(activities_path, item))])

# If no lang is specific, we will list the differences for all languages
if len(langs) == 0:
    langs = sorted([item for item in os.listdir(current_dir) if os.path.isdir(os.path.join(current_dir, item))])

for lang in langs:
    intro_path = os.path.join(current_dir, lang, "intro")
    if not os.path.isdir(intro_path):
        #print(f"Skip {lang} as it does not contain intro voices")
        continue
    for audio in os.listdir(intro_path):
        if not audio.endswith(".ogg"):
            continue
        if not os.path.splitext(audio)[0] in activities_list:
            print(f"{intro_path}/{audio}")
