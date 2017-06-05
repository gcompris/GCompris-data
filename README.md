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

TODO, full rcc should also contains background music
maybe we can improve to consume less size (multiple copies probably not needed/improvable)