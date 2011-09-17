//
//  NAUtils.m
//  SimpleSynth
//
//  Created by Boris Bügling on 17.09.11.
//  Copyright 2011 - All rights reserved.
//

#import "NAUtils.h"

static char *FormatError(char *str, OSStatus error) {
    *(UInt32 *)(str + 1) = CFSwapInt32HostToBig(error);
	
	// see if it appears to be a 4-char-code
    if (isprint(str[1]) && isprint(str[2]) && isprint(str[3]) && isprint(str[4])) {
        str[0] = str[5] = '\'';
        str[6] = '\0';
    } else {
        // no, format it as an integer
        sprintf(str, "%d", (int)error);
	}
    
	return str;
}

#pragma mark -

@implementation NAUtils

- (id)init
{
    return nil;
}

+ (BOOL)printErrorMessage:(NSString*)errorString withStatus:(OSStatus)result 
{
	if (noErr == result) return NO;
	
	char* resultString = (char *)malloc(7 * sizeof(char));
	resultString = FormatError(resultString, result);
	
	NSLog(@"*** %@ error: %s", errorString, resultString);
	free(resultString);
	
	return YES;
}

@end