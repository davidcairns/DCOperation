//
//  NSString+DCNetworkOperationAdditions.h
//  modash
//
//  Created by David Cairns on 2/3/12.
//  Copyright (c) 2012 MacOutfitters. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (DCNetworkOperationAdditions)

// Encodes a string according to RFC 3986 (similar to the rawurlencode function in PHP).
- (NSString *)urlEncodedString;

@end
