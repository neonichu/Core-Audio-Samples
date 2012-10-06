//
//  NARemoteIO.m
//  SimpleSynth
//
//  Created by Boris Bügling on 17.06.11.
//  Copyright 2011 - All rights reserved.
//

#import "NARemoteIO.h"

@implementation NARemoteIO

#pragma mark -
#pragma mark Initialize

-(id)init {
	self = [super initWithComponentType:kAudioUnitType_Output andComponentSubType:kAudioUnitSubType_RemoteIO];
	return self;
}

#pragma mark -

-(NSString*)description {
	return [NSString stringWithFormat:@"I/O Unit (Node: %ld, Unit: %d)", self.node, (int)self.unit];
}

@end