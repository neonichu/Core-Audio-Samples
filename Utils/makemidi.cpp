/*
 * Quick and dirty program for creating 128 MIDI files with one note each.
 *
 * Uses libmidi (https://github.com/kkrizka/libmidi)
 */

#include "MIDI.h"

#include <stdlib.h>

void create_midi_file(char* fileName, int note) {
	MIDI::File file(fileName);

	MIDI::Header *header = file.header();
	header->setTicksPerBeat(480);

	MIDI::Track *track = new MIDI::Track();

	MIDI::MetaGenericEvent *timeSignature = new MIDI::MetaGenericEvent(0, MIDI_METAEVENT_TIMESIGNATURE, 4);
	timeSignature->setParam(0, 4);
	timeSignature->setParam(1, 2);
	timeSignature->setParam(2, 24);
	timeSignature->setParam(3, 8);

	MIDI::MetaGenericEvent *keySignature = new MIDI::MetaGenericEvent(0, MIDI_METAEVENT_KEYSIGNATURE, 2);
	keySignature->setParam(0, 0);
	keySignature->setParam(1, 0);

	MIDI::MetaNumberEvent *tempo = new MIDI::MetaNumberEvent(0, MIDI_METAEVENT_SETTEMPO, 3, 900000);

	track->addEvent(timeSignature);
	track->addEvent(keySignature);
	track->addEvent(tempo);

	track->addEvent( new MIDI::ChannelEvent(0, MIDI_CHEVENT_NOTEON, 0, note, 100) );
	track->addEvent( new MIDI::ChannelEvent(1000, MIDI_CHEVENT_NOTEOFF, 0, note, 0) );

	track->addEvent( new MIDI::MetaGenericEvent(25, MIDI_METAEVENT_ENDOFTRACK, 0) );

	file.addTrack(track);

	file.write();
}

int main(int argc, char *argv[]) {
	for (int i=0;i<128;i++) {
		char fileName[128];
		snprintf(fileName, 128, "note-%i.mid", i);
		create_midi_file(fileName, i);
	}

	return 0;
}
