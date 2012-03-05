//
//  NSString+DCNetworkOperationAdditions.m
//  modash
//
//  Created by David Cairns on 2/3/12.
//  Copyright (c) 2012 MacOutfitters. All rights reserved.
//

#import "NSString+DCNetworkOperationAdditions.h"

@implementation NSString (DCNetworkOperationAdditions)

- (NSString *)urlEncodedString {
	// NOTE: Algorithm taken from http://mesh.typepad.com/blog/2007/10/url-encoding-wi.html --DRC

	// Define the characters we'll have to encode, and the codes we'll replace them with.
	NSDictionary *conversionDict = [NSDictionary dictionaryWithObjectsAndKeys:
									@"%3B", @";", 
									@"%2F", @"/", 
									@"%3F", @"?", 
									@"%3A", @":", 
									@"%40", @"@", 
									@"%26", @"&", 
									@"%3D", @"=", 
									@"%2B", @"+", 
									@"%24", @"$", 
									@"%2C", @",", 
									@"%5B", @"[", 
									@"%5D", @"]", 
									@"%23", @"#", 
									@"%21", @"!", 
									@"%27", @"'", 
									@"%28", @"(", 
									@"%29", @")", 
									@"%2A", @"*", 
									// NOTE: I've had to add these: --DRC
									@"%20", @" ", 
									@"%3C", @"<", 
									@"%3E", @">", 
									@"%22", @"\"", 
									nil];
	
	NSMutableString *conversionString = [NSMutableString stringWithString:self];
	for(NSString *characterToReplace in conversionDict.allKeys) {
		[conversionString replaceOccurrencesOfString:characterToReplace withString:[conversionDict objectForKey:characterToReplace] options:NSLiteralSearch range:NSMakeRange(0, conversionString.length)];
	}

	return [NSString stringWithString:conversionString];
}

@end
