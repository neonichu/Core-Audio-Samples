#!/bin/sh

#
## Convert a SoundFont + MIDI file to a CAF audio file.
##
## needs:
## fluidsynth, sox (installable via brew)
## afconvert (part of OS X)
#

if [ "$#" -lt 2 ]
then
  echo "Usage: `basename $0` [SoundFont] [MIDI]"
  exit 1
fi

SOUNDFONT="$1"
MIDI="$2"
OUT="`basename \"$SOUNDFONT\" .sf2`.wav"

# Play MIDI file using the given SoundFont
fluidsynth -nli -F "temp.raw" "$SOUNDFONT" "$MIDI" >/dev/null
# Convert raw output to WAV
sox -r 44100 -2 -c 2 -s "temp.raw" "temp.wav"
# Trim the WAV to one second
sox "temp.wav" "$OUT" trim 0.0 1.0
# Convert the WAV to CAF
afconvert -f caff -d LEI16 "$OUT"
# Cleanup
rm -f temp.raw temp.wav "$OUT"
