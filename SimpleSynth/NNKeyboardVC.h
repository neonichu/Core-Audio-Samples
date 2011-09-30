//
//  NNKeyboardVC.h
//  SimpleSynth
//
//  Created by Boris Bügling on 17.06.11.
//  Copyright 2011 - All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LevelMeterView.h"
#import "NNKeyboard.h"
#import "SynthController.h"

@interface NNKeyboardVC : UIViewController

@property (nonatomic, retain) LevelMeterView* levelMeter;
@property (nonatomic, assign) NNKeyboard* keyboard;
@property (nonatomic, assign) SynthController* synthController;

@end