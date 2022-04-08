# gcompris-data
This repository contains all the data used in GCompris that is not shipped directly:
* voices
* images dataset (for lang, hangman...)
* background music

Background music is generated in background-music/.rcc/
Voices are generated in voices/$AUDIO_CODEC/voices-$AUDIO_CODEC
Words dataset is generated in voices/ogg/.rcc/words/
Full rcc (words+voices) are in voices/$AUDIO_CODEC/.rcc

It takes around 3Go to generate all the data.

Starting GCompris 2.4, we have updated all the png images to webp. To keep compatibility with older versions, we have created a new words-webp rcc file and kept the words/words folder (with png images).
We should not update it anymore and all new updates should be done in the words-webp folder.

TODO, full rcc should also contains background music
maybe we can improve to consume less size (multiple copies probably not needed/improvable)