//
//  NNKeyboard.h
//  SimpleSynth
//
//  Created by Boris Bügling on 25.09.11.
//  Copyright (c) 2011 - All rights reserved.
//

#import "NNAudio.h"

#define kBlackKeyOffset     100

typedef enum {
    NNKey_C        = 0,
    NNKey_CHash    = 0 + kBlackKeyOffset,
    NNKey_D        = 1,
    NNkey_DHash    = 1 + kBlackKeyOffset,
    NNKey_E        = 2,
    NNKey_F        = 3,
    NNKey_FHash    = 3 + kBlackKeyOffset,
    NNKey_G        = 4,
    NNKey_GHash    = 4 + kBlackKeyOffset,
    NNKey_A        = 5,
    NNKey_AHash    = 5 + kBlackKeyOffset,
    NNKey_B        = 6,
} NNKey;

@interface NNKeyboard : NAMixer

-(void)pressKey:(NNKey)key;

@end