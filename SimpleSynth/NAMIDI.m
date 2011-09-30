//
//  NAMIDI.m
//  SimpleSynth
//
//  Created by Boris Bügling on 17.06.11.
//  Copyright 2011 - All rights reserved.
//

#import <CoreMIDI/CoreMIDI.h>

#import "NAMIDI.h"

static void	MyMIDIReadProc(const MIDIPacketList *pktlist, void *refCon, void *connRefCon)
{
	MIDIPacket *packet = (MIDIPacket *)pktlist->packet;	
	Byte midiCommand = packet->data[0] >> 4;
    
	if (midiCommand == 0x09) { // "Note On" Event
		Byte note = packet->data[1] & 0x7F;
		Byte velocity = packet->data[2] & 0x7F;
        
        NSMutableDictionary* info = [[NSMutableDictionary alloc] init];
        [info setObject:[NSNumber numberWithShort:note] forKey:kNAMIDI_NoteKey];
        [info setObject:[NSNumber numberWithShort:velocity] forKey:kNAMIDI_VelocityKey];
        NSNotification* notification = [NSNotification notificationWithName:kNAMIDINoteOnNotification object:nil userInfo:info];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
	}	
}

static void MyMIDINotifyProc (const MIDINotification  *message, void *refCon) {
    NSNotification* notification = [NSNotification notificationWithName:kNAMIDINotification 
                                                                 object:[NSNumber numberWithShort:message->messageID]];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

@implementation NAMIDI

- (void)setupMIDI { 
	MIDIClientRef client = NULL;
	MIDIClientCreate(CFSTR("NNAudio MIDI Handler"), MyMIDINotifyProc, nil, &client);
	
	MIDIPortRef inPort = NULL;
	MIDIInputPortCreate(client, CFSTR("Input port"), MyMIDIReadProc, nil, &inPort);
	
	unsigned long sourceCount = MIDIGetNumberOfSources();
	for (int i = 0; i < sourceCount; ++i) {
		MIDIEndpointRef src = MIDIGetSource(i);
		/*CFStringRef endpointName = NULL;
		OSStatus nameErr = MIDIObjectGetStringProperty(src, kMIDIPropertyName, &endpointName);
		if (noErr == nameErr) {
            NSLog(@"MIDI source %d: %@", i, endpointName);
		}*/
		MIDIPortConnectSource(inPort, src, NULL);
	}
}


- (id)init
{
    self = [super init];
    if (self) {
        [self setupMIDI];
    }
    return self;
}

@end