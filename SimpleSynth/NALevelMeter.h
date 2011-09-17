//
//  NALevelMeter.h
//  SimpleSynth
//
//  Created by Boris Bügling on 17.09.11.
//  Copyright 2011 - All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>

@protocol NALevelMeterDelegate

-(void)peakPowerChangedTo:(float)peakPower;

@end


@interface NALevelMeter : NSObject 
{
    @public Float32 peakPowers[2];
}

@property (nonatomic, assign) id <NALevelMeterDelegate> delegate;
@property (nonatomic, readonly) AURenderCallback renderCallback;

- (float)peakPowerForChannel:(NSInteger)channelNumber;

@end
