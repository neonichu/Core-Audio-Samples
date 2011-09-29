//
//  LevelMeterView.m
//  SimpleSynth
//
//  Created by Boris Bügling on 30.09.11.
//  Copyright (c) 2011 - All rights reserved.
//

#import "LevelMeterView.h"

@interface LevelMeterView ()

@property (nonatomic, assign) CGRect innerRect;

@end

#pragma -

@implementation LevelMeterView

@synthesize innerRect;

- (id)init {
    self = [super init];
    if (self) {
        self.innerRect = CGRectNull;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextFillRect(context, self.bounds);
    
    CGContextSetFillColorWithColor(context, [UIColor redColor].CGColor);
    CGContextFillRect(context, self.innerRect);
}

- (void)peakPowerChangedTo:(float)peakPower {
    CGFloat width = (fabs(DBOFFSET) + peakPower) * (self.frame.size.width / fabs(DBOFFSET));
    CGFloat height = (fabs(DBOFFSET) + peakPower) * (self.frame.size.height / fabs(DBOFFSET));
    CGFloat x = (self.frame.size.width - width) / 2.0;
    CGFloat y = (self.frame.size.height - height) / 2.0;
    
    self.innerRect = CGRectMake(x, y, width, height);
    [self performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:NO];
}

@end