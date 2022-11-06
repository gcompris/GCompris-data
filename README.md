# gcompris-data

This repository contains all the data used in GCompris that is not shipped directly:
* voices
* images dataset (for lang, hangman...)
* background music

Background music is generated in `background-music/.rcc/` <br/>
Voices are generated in `voices/$AUDIO_CODEC/voices-$AUDIO_CODEC`<br/>
Words dataset is generated in `voices/ogg/.rcc/words/`<br/>
Full rcc (words+voices) are in `voices/$AUDIO_CODEC/.rcc`<br/>

It takes around 3 GB of disk space to generate all the data.

Starting with GCompris 2.4, we have updated all the png images to webp. To keep compatibility with the older versions, we have created a new words-webp rcc file and kept the words/words folder (with png images).
We should not update it anymore and all new updates should be done in the words-webp folder.

TODO: full rcc should also contain background music.
Maybe we can improve to consume less disk space (multiple copies probably not needed).
