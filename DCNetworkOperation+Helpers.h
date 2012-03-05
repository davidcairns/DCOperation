/*
 *  DCNetworkOperation+Helpers.h
 *
 *  Created by David Cairns on 1/24/11.
 *  Copyright 2011 David Cairns. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>

// Convenience functions for doing e.g. file transfers.
NSString *DCHeaderFieldForFileTransfer();
NSData *DCDataWithFileAndParamName(NSString *filename, NSString *paramName);

// Convenience function(s) for combing regular parameters with a file transfer.
NSData *DCDataForValueAndParamName(NSString *value, NSString *paramName);
