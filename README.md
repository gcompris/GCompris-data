# gcompris-data

This repository contains all the data used in GCompris that is not shipped directly:
* `voices`
* `words` (contains image dataset used for lang, hangman...)
* `background-music`

The scripts to generate rcc files are in the `scripts` folder. Navigate to the scripts folder and run `main_generate_rcc.sh`. You may need to adjust the `RCC` variable in the script to the path of the rcc executable in your Qt installation.

By default, the script fetches the current `Contents` file from the server to see which files need to be updated, and generate only those rcc (plus the full rcc files). You can force the script to generate all rcc files by adding the "force" argument.

By default, the script converts all ogg audio files (to mp3 and aac) to be able to generate full-xxx.rcc files. You can use the argument "skipFullRcc" to convert only the audio files required to generate the rcc files which need to be updated and skip generating the full-xxx.rcc files.

The "force" and "skipFullRcc" arguments are mutually exclusive, use only one at a time.

All generated rcc files are stored in `scripts/data3/`, the same way they are stored on the server.

It takes around 3 GB of disk space to generate all the data.

Starting with GCompris 2.4, we have updated all the png images to webp. To keep compatibility with the older versions, we have created a new words-webp rcc file and kept the words/words folder (with png images).
We should not update it anymore and all new updates should be done in the words-webp folder.

