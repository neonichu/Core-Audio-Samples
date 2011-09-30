//
//  NNKeyboardVC.m
//  SimpleSynth
//
//  Created by Boris Bügling on 17.06.11.
//  Copyright 2011 - All rights reserved.
//

#import "NNKeyboardVC.h"

@implementation NNKeyboardVC

@synthesize documentInteractionController;
@synthesize keyboard;
@synthesize levelMeter;
@synthesize openRecordingButton;
@synthesize recorder;
@synthesize synthController;

#pragma mark -

+(NSString*)pathToFileInDocumentsDirectoryWithName:(NSString*)name {
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	if ([paths count] < 1) {
		return name;
	}
    return [[paths objectAtIndex:0] stringByAppendingPathComponent:name];
}

#pragma mark - View lifecycle

- (void)setupButton:(UIButton*)button 
{
    [button addTarget:self action:@selector(keyPressed:) forControlEvents:UIControlEventTouchDown];
    [button setBackgroundImage:[UIImage imageNamed:@"ButtonHighlighted"] forState:UIControlStateHighlighted];
}

- (void)addSwitchWithText:(NSString*)text actionSelector:(SEL)actionSelector atPosition:(CGPoint)position {
    UILabel* switchLabel = [[UILabel alloc] initWithFrame:CGRectMake(position.x, position.y, 100.0, 20.0)];
    switchLabel.backgroundColor = [UIColor clearColor];
    switchLabel.textColor = [UIColor whiteColor];
    switchLabel.text = text;
    [self.view addSubview:switchLabel];
    
    UISwitch* switchButton = [[UISwitch alloc] initWithFrame:CGRectMake(position.x + switchLabel.frame.size.width + 10.0, position.y - 5.0, 
                                                                        switchLabel.frame.size.width, switchLabel.frame.size.height)];
    switchButton.on = NO;
    [switchButton addTarget:self action:actionSelector forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:switchButton];
}

- (void)loadView
{
    self.view = [[UIView alloc] init];
    
    CGFloat x = 64.0;
    for (int i = 0; i < 7; i++) {
        UIButton* whiteKey = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        
        whiteKey.frame = CGRectMake(x, 386.0, 128.0, 362.0);
        whiteKey.tag = i;
        
        [self setupButton:whiteKey];
        [self.view insertSubview:whiteKey atIndex:0];
        
        x += whiteKey.frame.size.width;
        
        
        UIButton* blackKey;
        
        switch (i) {
            case 0:
            case 1:
            case 3:
            case 4:
            case 5:
                blackKey = [UIButton buttonWithType:UIButtonTypeCustom];
                
                blackKey.backgroundColor = [UIColor blackColor];
                blackKey.frame = CGRectMake(x - 44.0, whiteKey.frame.origin.y, 88.0, 240.0);
                blackKey.tag = i + kBlackKeyOffset;
                
                [self setupButton:blackKey];
                [self.view addSubview:blackKey];
                break;
        }
    }
    
    self.levelMeter = [[LevelMeterView alloc] init];
    self.levelMeter.frame = CGRectMake(824.0, 0.0, 200.0, 200.0);
    [self.view addSubview:self.levelMeter];
    
    [self addSwitchWithText:@"Effect" actionSelector:@selector(effectSwitchToggled:) atPosition:CGPointMake(50.0, 50.0)];
    [self addSwitchWithText:@"Sine Wave" actionSelector:@selector(sineWaveToggled:) atPosition:CGPointMake(50.0, 90.0)];
    [self addSwitchWithText:@"Record" actionSelector:@selector(recordToggled:) atPosition:CGPointMake(50.0, 130.0)];
    
    self.openRecordingButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.openRecordingButton.alpha = 0.5;
    self.openRecordingButton.enabled = NO;
    self.openRecordingButton.frame = CGRectMake(50.0, 200.0, 150.0, 50.0);
    [self.openRecordingButton addTarget:self action:@selector(openRecordingClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.openRecordingButton setTitle:@"Open Recording" forState:UIControlStateHighlighted];
    [self.openRecordingButton setTitle:@"Open Recording" forState:UIControlStateNormal];
    [self.view addSubview:self.openRecordingButton];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

#pragma mark - Actions

- (void)effectSwitchToggled:(UISwitch*)effectSwitch 
{
    self.synthController.reverbEffect.active = effectSwitch.on;
}

- (void)keyPressed:(UIButton*)button
{
    [self.keyboard pressKey:button.tag];
}

- (void)openRecordingClicked:(UIButton*)button {
    NSURL* url = [NSURL fileURLWithPath:[self.recorder pathToRecording]];
    self.documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:url];
    //[self.documentInteractionController presentPreviewAnimated:YES];
    [self.documentInteractionController presentOpenInMenuFromRect:button.frame inView:self.view animated:YES];
}

- (void)recordToggled:(UISwitch*)recordSwitch
{
    NANode* targetNode = self.synthController.reverbEffect;
    
    if (recordSwitch.on) {
        if (!self.recorder) {
            self.recorder = [[NARecorder alloc] initWithInputFormat:[targetNode outputDescription] 
                                                         sampleRate:[targetNode outputSampleRate]];
            [targetNode attachRenderNotifier:self.recorder.renderCallback withUserData:(__bridge void*)self.recorder];
        }
            
        [self.recorder enableRecordingToPath:[[self class] pathToFileInDocumentsDirectoryWithName:@"recording.m4a"]];
    } else {
        [self.recorder closeRecording];
    }
    
    self.openRecordingButton.alpha = recordSwitch.on ? 0.5 : 1.0;
    self.openRecordingButton.enabled = !recordSwitch.on;
}

- (void)sineWaveToggled:(UISwitch*)sineWaveSwitch
{
    
}

#pragma mark - Rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

@end