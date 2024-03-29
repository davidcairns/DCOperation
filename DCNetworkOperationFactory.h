//
//  DCNetworkOperationFactory.h
//  modash
//
//  Created by David Cairns on 2/8/12.
//  Copyright (c) 2012 MacOutfitters. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DCNetworkOperation.h"
#import "DCFileDownloadOperation.h"

@interface DCNetworkOperationFactory : NSObject

@property(nonatomic, assign)NSTimeInterval timeoutInterval;
@property(nonatomic, copy)NSString *baseURLString;
@property(nonatomic, copy)NSDictionary *headerFields;

@property(nonatomic, copy)NSString *authenticationUserName;
@property(nonatomic, copy)NSString *authenticationPassword;

// This will create a network operation from our factory state.
- (DCNetworkOperation *)networkOperationForHTTPMethod:(NSString *)httpMethod apiMethod:(NSString *)apiMethod;

// Convenience methods for downloading a file.
- (DCFileDownloadOperation *)downloadOperationForFile:(NSString *)relativeFile destinationURL:(NSURL *)destinationURL;

// Set a key/value pair that will be set on all subsequently-created network operations.
- (void)setRequestValue:(NSString *)value forParameter:(NSString *)parameter;

// The block to be called by each operation when it needs to process its response data.
// Generally, you'd interpret the response data as e.g. JSON and parse it in to the network
//	operation's responseDictionary object.
@property(nonatomic, copy)DCResponseProcessingBlock responseProcessingBlock;

@end
