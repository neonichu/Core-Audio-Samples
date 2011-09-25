//
//  NNKeyboardVC.m
//  SimpleSynth
//
//  Created by Boris Bügling on 17.06.11.
//  Copyright 2011 - All rights reserved.
//

#import "NNKeyboardVC.h"

@implementation NNKeyboardVC

@synthesize keyboard;

#pragma mark - View lifecycle

- (void)setupButton:(UIButton*)button 
{
    [button addTarget:self action:@selector(keyPressed:) forControlEvents:UIControlEventTouchUpInside];
    [button setBackgroundImage:[UIImage imageNamed:@"ButtonHighlighted"] forState:UIControlStateHighlighted];
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
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

#pragma mark - Actions

- (void)keyPressed:(UIButton*)button
{
    [self.keyboard pressKey:button.tag];
}

#pragma mark - Rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

@end