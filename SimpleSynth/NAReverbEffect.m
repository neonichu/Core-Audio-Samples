//
//  NAReverbEffect.m
//  SimpleSynth
//
//  Created by Boris Bügling on 17.06.11.
//
//  Source: http://code.google.com/p/mobilesynth/
//

#import "NAReverbEffect.h"

static const float kSampleRate = 44100.0f;
static const float kE = 2.71828183f;

#pragma mark -

@interface NAReverbEffect ()

@property (nonatomic, assign) float oldx, oldy1, oldy2, oldy3, y1, y2, y3, y4;

@end

#pragma mark -

static float filter_audio(NAReverbEffect* effect, float x) {
    float f = 2.0f * effect.cutoff / kSampleRate;
    float k = 3.6f * f - 1.6f * f * f - 1;
    float p = (k + 1.0f) * 0.5f;
    float scale = powf(kE, (1.0f - p) * 1.386249);
    float r = effect.resonance * scale;
    
    float result = x - r * effect.y4;
    effect.y1 = result * p + effect.oldx * p - k * effect.y1;
    effect.y2 = effect.y1 * p + effect.oldy1 * p - k * effect.y2;
    effect.y3 = effect.y2 * p + effect.oldy2 * p - k * effect.y3;
    effect.y4 = effect.y3 * p + effect.oldy3 * p - k * effect.y4;
    effect.y4 = effect.y4 - powf(effect.y4, 3.0f) / 6.0f;
    effect.oldx = result;
    effect.oldy1 = effect.y1;
    effect.oldy2 = effect.y2;
    effect.oldy3 = effect.y3;
    
    return result;
}

@implementation NAReverbEffect

@synthesize cutoff, resonance;
@synthesize oldx, oldy1, oldy2, oldy3, y1, y2, y3, y4;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

@end