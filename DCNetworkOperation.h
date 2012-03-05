//
//  DCNetworkOperation.h
//
//  Created by David Cairns on 11/21/10.
//  Copyright 2010 David Cairns. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DCOperation.h"
#import "NSString+DCNetworkOperationAdditions.h"

@class DCNetworkOperation;
typedef void (^DCResponseProcessingBlock)(DCNetworkOperation *networkOperation);


@interface DCNetworkOperation : DCOperation

@property(nonatomic, copy)NSString *urlString;
@property(nonatomic, copy)NSString *HTTPMethod;
@property(nonatomic, copy)NSDictionary *headerFields;

// NOTE: One may provide data via either a key/value-style approach (which supports uploading 
//			files, etc), or by providing just the raw data. These methods are not compatible
//			with one another. --DRC

// Key / Value API.
- (NSString *)requestValueForParameter:(NSString *)parameter;
- (void)setRequestValue:(NSString *)value forParameter:(NSString *)parameter;
- (void)setRequestFilename:(NSString *)filename forParameter:(NSString *)parameter;
// Raw-data API.
- (void)setRequestData:(NSData *)requestData;

// This fields are populated during execution of the URL request.
@property(nonatomic, assign, readonly)long long expectedContentLength;
@property(nonatomic, strong, readonly)NSData *responseData;

// This block is called every time the operation receives data.
@property(nonatomic, copy)dispatch_block_t transferUpdateBlock;

// The block to be called by each operation when it needs to process its response data.
// Generally, you'd interpret the response data as e.g. JSON and parse it in to the network
//	operation's responseDictionary object.
@property(nonatomic, copy)DCResponseProcessingBlock responseProcessingBlock;

// Authentication
@property(nonatomic, copy)NSString *authenticationUserName;
@property(nonatomic, copy)NSString *authenticationPassword;

@end
