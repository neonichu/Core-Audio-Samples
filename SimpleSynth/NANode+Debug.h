//
//  NANode.h
//  SimpleSynth
//
//  Created by Boris Bügling on 17.06.11.
//  Copyright 2011 - All rights reserved.
//

#import "NANode.h"

@interface NANode (Debug)

-(void)printACD:(AudioComponentDescription)acd;
-(void)printASBD:(AudioStreamBasicDescription)asbd;

@end