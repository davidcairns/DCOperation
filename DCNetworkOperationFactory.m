//
//  DCNetworkOperationFactory.m
//  modash
//
//  Created by David Cairns on 2/8/12.
//  Copyright (c) 2012 MacOutfitters. All rights reserved.
//

#import "DCNetworkOperationFactory.h"
#import "DCOperation+ARCSupport.h"

@interface DCNetworkOperationFactory ()
@property(nonatomic, strong)NSMutableDictionary *parametersToValues;
@end

@implementation DCNetworkOperationFactory
@synthesize timeoutInterval = _timeoutInterval;
@synthesize baseURLString = _baseURLString;
@synthesize headerFields = _headerFields;
@synthesize authenticationUserName = _authenticationUserName;
@synthesize authenticationPassword = _authenticationPassword;
@synthesize responseProcessingBlock = _responseProcessingBlock;
@synthesize parametersToValues = _parametersToValues;

- (id)init {
	if((self = [super init])) {
		self.parametersToValues = [NSMutableDictionary dictionary];
	}
	return self;
}
- (void)dealloc {
	DC_RELEASE(_baseURLString);
	DC_RELEASE(_headerFields);
	DC_RELEASE(_authenticationUserName);
	DC_RELEASE(_authenticationPassword);
	DC_RELEASE(_parametersToValues);
	DC_RELEASE(_responseProcessingBlock);
	
#if !defined(DC_USE_ARC)
	[super dealloc];
#endif
}

- (DCNetworkOperation *)networkOperationForHTTPMethod:(NSString *)httpMethod apiMethod:(NSString *)apiMethod {
	DCNetworkOperation *op = DC_AUTORELEASE([[DCNetworkOperation alloc] init]);
	op.HTTPMethod = httpMethod;
	op.timeoutInterval = self.timeoutInterval;
	op.headerFields = self.headerFields;
	op.authenticationUserName = self.authenticationUserName;
	op.authenticationPassword = self.authenticationPassword;
	op.responseProcessingBlock = self.responseProcessingBlock;
	
	op.urlString = [NSString stringWithFormat:@"%@%@", self.baseURLString, apiMethod];
	
	// Add each of our global parameters to this operation.
	[self.parametersToValues enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		[op setRequestValue:obj forParameter:key];
	}];
	
	return op;
}

- (DCFileDownloadOperation *)downloadOperationForFile:(NSString *)relativeFile destinationURL:(NSURL *)destinationURL {
	NSString *urlString = [NSString stringWithFormat:@"%@%@", self.baseURLString, relativeFile];
	DCFileDownloadOperation *downloadOperation = [[DCFileDownloadOperation alloc] initWithURLString:urlString destinationURL:destinationURL];
	
	// Add our custom fields (except timeout!).
	downloadOperation.headerFields = self.headerFields;
	downloadOperation.authenticationUserName = self.authenticationUserName;
	downloadOperation.authenticationPassword = self.authenticationPassword;
	
	// Add each of our global parameters to this operation.
	[self.parametersToValues enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		[downloadOperation setRequestValue:obj forParameter:key];
	}];
	
	return downloadOperation;
}


#pragma mark -
- (void)setRequestValue:(NSString *)value forParameter:(NSString *)parameter {
	// Make sure the value has some content.
	value = value ?: @"";
	[self.parametersToValues setObject:value forKey:parameter];
}

@end
