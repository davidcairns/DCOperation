//
//  DCNetworkOperation.m
//
//  Created by David Cairns on 11/21/10.
//  Copyright 2010 David Cairns. All rights reserved.
//

#import "DCNetworkOperation.h"
#import "DCNetworkOperation+Helpers.h"
#import "DCOperation+ARCSupport.h"

NSString *DCNetworkOperationErrorDomain = @"DCNetworkOperationErrorDomain";

@interface NSString (DCNetworkEncoding)

@end
@implementation NSString (DCNetworkEncoding)

- (NSString *)DC_stringByEscapingForURLArgument {
	// Encode all the reserved characters, per RFC 3986 (<http://www.ietf.org/rfc/rfc3986.txt>)
	CFStringRef escaped = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)self, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8);
	return DC_AUTORELEASE((__bridge_transfer NSString *)escaped);
}

@end


@interface DCNetworkOperation ()
@property(nonatomic, strong)NSURLConnection *urlConnection;
@property(nonatomic, assign)long long expectedContentLength;
@property(nonatomic, strong)NSMutableData *mutableResponseData;

@property(nonatomic, strong)NSMutableDictionary *parametersToValues;
@property(nonatomic, strong)NSMutableSet *parametersRepresentingFiles;
@property(nonatomic, strong)NSData *rawRequestData;

- (NSData *)_requestBodyData;
@end

@implementation DCNetworkOperation
@synthesize urlString = _urlString;
@synthesize HTTPMethod = _HTTPMethod;
@synthesize headerFields = _headerFields;
@synthesize expectedContentLength = _expectedContentLength;
@synthesize mutableResponseData = _mutableResponseData;
@synthesize urlConnection = _urlConnection;
@synthesize parametersToValues = _parametersToValues;
@synthesize parametersRepresentingFiles = _parametersRepresentingFiles;
@synthesize rawRequestData = _rawRequestData;
@synthesize transferUpdateBlock = _transferUpdateBlock;
@synthesize authenticationUserName = _authenticationUserName;
@synthesize authenticationPassword = _authenticationPassword;
@synthesize responseProcessingBlock = _responseProcessingBlock;

- (id)init {
	if((self = [super init])) {
		self.HTTPMethod = @"GET";
		self.timeoutInterval = 30.0;
		self.needsRunLoop = YES;
		
		self.parametersToValues = [NSMutableDictionary dictionary];
		self.parametersRepresentingFiles = [NSMutableSet set];
	}
	return self;
}
- (void)dealloc {
	DC_RELEASE(_urlString);
	DC_RELEASE(_HTTPMethod);
	DC_RELEASE(_headerFields);
	DC_RELEASE(_urlConnection);
	DC_RELEASE(_mutableResponseData);
	DC_RELEASE(_parametersToValues);
	DC_RELEASE(_parametersRepresentingFiles);
	DC_RELEASE(_rawRequestData);
	DC_RELEASE(_transferUpdateBlock);
	DC_RELEASE(_authenticationUserName);
	DC_RELEASE(_authenticationPassword);
	DC_RELEASE(_responseProcessingBlock);
	
#if !defined(DC_USE_ARC)
	[super dealloc];
#endif
}


#pragma mark -
- (NSString *)requestValueForParameter:(NSString *)parameter {
	return [self.parametersToValues objectForKey:parameter];
}
- (void)setRequestValue:(NSString *)value forParameter:(NSString *)parameter {
	// Force the request data to be rebuilt.
	self.rawRequestData = nil;
	
	// Make sure that this parameter is not marked a file.
	[self.parametersRepresentingFiles removeObject:parameter];
	
	if(value) {
		// Set the new value.
		[self.parametersToValues setValue:value forKey:parameter];
	}
	else {
		[self.parametersToValues removeObjectForKey:parameter];
	}
}
- (void)setRequestFilename:(NSString *)filename forParameter:(NSString *)parameter {
	// Clear out the raw request data, if it's been set.
	self.rawRequestData = nil;
	
	// Set the new value.
	[self.parametersToValues setObject:filename forKey:parameter];
	
	// Make sure this parameter is marked as a file.
	[self.parametersRepresentingFiles addObject:parameter];
}

- (void)setRequestData:(NSData *)requestData {
	[self.parametersToValues removeAllObjects];
	[self.parametersRepresentingFiles removeAllObjects];
	self.rawRequestData = requestData;
}

#pragma mark -
- (NSURLRequest *)_urlRequest {
	// Determine the real URL string to use.
	NSMutableString *urlStringToUse = [NSMutableString stringWithString:self.urlString];
	// If this is a GET request and we have parameters, we need to embed them in the URL.
	if([self.HTTPMethod isEqualToString:@"GET"]) {
		__block BOOL isFirstArgument = YES;
		[self.parametersToValues enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			if(isFirstArgument) {
				// Make sure the argument section starts with a '?'.
				[urlStringToUse appendString:@"?"];
				isFirstArgument = NO;
			}
			else {
				[urlStringToUse appendString:@"&"];
			}
			
			// If the object is a string, escape its contents.
			id objToUse = [obj isKindOfClass:[NSString class]] ? [obj DC_stringByEscapingForURLArgument] : obj;
			[urlStringToUse appendFormat:@"%@=%@", key, objToUse];
		}];
	}
	
	// Set up our URL request.
	NSURL *url = [NSURL URLWithString:urlStringToUse];
	NSMutableURLRequest *request = DC_AUTORELEASE([[NSMutableURLRequest alloc] init]);
	[request setURL:url];
	[request setHTTPMethod:self.HTTPMethod];
	
	// Add the HTTP header fields.
	NSDictionary *headerFields = [self headerFields];
	if(headerFields) {
		// Override each of these fields.
		for(NSString *key in [headerFields allKeys]) {
			[request addValue:[headerFields objectForKey:key] forHTTPHeaderField:key];
		}
	}
	
	// Add the request body.
	NSData *requestBody = [self _requestBodyData];
	if(requestBody) {
		[request setHTTPBody:requestBody];
	}
//	NSLog(@"Request URL: %@, HTTP method:%@, header fields:%@, body:%@", [request URL], [request HTTPMethod], [request allHTTPHeaderFields], requestBody ? self.parametersToValues : nil);
	
	return request;
}

- (BOOL)operationShouldStart {
	// Check the preflight test to see if our request is valid.
	NSURLRequest *request = [self _urlRequest];
	if(![NSURLConnection canHandleRequest:request]) {
		self.error = [NSError errorWithDomain:DCNetworkOperationErrorDomain code:DCNetworkOperationErrorCodeBadRequest userInfo:nil];
		return NO;
	}
	
	// Set up the mutable data buffer into which we'll store our result.
	self.mutableResponseData = [NSMutableData data];
	
	// Set up our NSURLConnection.
	self.urlConnection = DC_AUTORELEASE([[NSURLConnection alloc] initWithRequest:request delegate:self]);
	
	// Schedule the NSURLConnection to run on the main run loop.
#if TARGET_OS_IPHONE
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
#endif
	[self.urlConnection start];
	
	return YES;
}
- (void)operationDidFinish {
	[super operationDidFinish];
	
#if TARGET_OS_IPHONE
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
#endif
	
	// Kill our URL connection.
	[self.urlConnection cancel];
	self.urlConnection = nil;
	
	// Call our response-processing block.
	if(self.responseProcessingBlock) {
		self.responseProcessingBlock(self);
	}
}


- (NSData *)responseData {
	return self.mutableResponseData;
}

#pragma mark -
- (BOOL)_useFormStyleRequestBodyData {
	return [self.parametersRepresentingFiles count] > 0;
}
- (NSData *)_formStyleRequestBodyData {
	NSMutableData *requestBodyData = [NSMutableData data];
	for(NSString *parameter in [self.parametersToValues allKeys]) {
		NSString *value = [self.parametersToValues objectForKey:parameter];
		
		if([self.parametersRepresentingFiles containsObject:parameter]) {
			// This parameter represents a file, use our special path.
			[requestBodyData appendData:DCDataWithFileAndParamName(value, parameter)];
		}
		else {
			// This is just a regular parameter but we're in form-style mode.
			[requestBodyData appendData:DCDataForValueAndParamName(value, parameter)];
		}
	}
	return requestBodyData;
}
- (NSData *)_argumentStyleRequestBodyData {
	NSMutableString *string = [NSMutableString string];
	for(NSString *parameter in [self.parametersToValues allKeys]) {
		NSString *value = [self.parametersToValues objectForKey:parameter];
		[string appendFormat:@"%@=%@;", parameter, value];
	}
	return [string dataUsingEncoding:NSUTF8StringEncoding];
}
- (NSData *)_requestBodyData {
	// GET requests shouldn't have a POST body.
	if([self.HTTPMethod isEqualToString:@"GET"]) {
		return nil;
	}
	
	// If we have raw request data, just use that.
	if(self.rawRequestData) {
		return self.rawRequestData;
	}
	
	// Otherwise, build the request body data buffer based on our parameter dictionary.
	return [self _useFormStyleRequestBodyData] ? [self _formStyleRequestBodyData] : [self _argumentStyleRequestBodyData];
}


#pragma mark -
- (float)progress {
	if(-1 == self.expectedContentLength || 0 == self.expectedContentLength) {
		return DCProgressIndeterminate;
	}
	
	return self.responseData.length / self.expectedContentLength;
}


#pragma mark - NSURLConnectionDelegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	// Store the expected content size, so we can refer to it later.
	self.expectedContentLength = response.expectedContentLength;
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	// We've received some data; append it to our data buffer.
	[self.mutableResponseData appendData:data];
	if(self.transferUpdateBlock) {
		self.transferUpdateBlock();
	}
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	// Our url connection failed!
	
	NSDictionary *errorUserInfo = [NSDictionary dictionaryWithObject:error forKey:NSUnderlyingErrorKey];
	self.error = [NSError errorWithDomain:DCNetworkOperationErrorDomain code:DCNetworkOperationErrorCodeConnectionFailed userInfo:errorUserInfo];
	
	// Clean up.
	[self finish];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	// Clean up.
	[self finish];
}


#pragma mark - NSURLConnectionDelegate Authentication
- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	if(challenge.previousFailureCount) {
		NSLog(@"Authentication challenge was rejected!");
		[challenge.sender cancelAuthenticationChallenge:challenge];
		[self.urlConnection cancel];
		return;
	}
	
	// If this is a trust challenge, create a credential for that.
	if([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
		// First, evaluate the trust.
		SecTrustResultType evaluationResult;
		OSStatus err = SecTrustEvaluate(challenge.protectionSpace.serverTrust, &evaluationResult);
		if(err) {
			NSLog(@"Failed to evaluate the trust, with error: %ld", err);
			return;
		}
		
		// If the trust is invalid, cancel the authentication challenge.
		if(kSecTrustResultInvalid == evaluationResult) {
			NSLog(@"The server trust challenge was invalid!");
			[challenge.sender cancelAuthenticationChallenge:challenge];
		}
		
		// Create a credential to respond to the trust.
		NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
		[challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
	}
	else if([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodHTTPBasic]) {
		if(!self.authenticationUserName || !self.authenticationPassword) {
			NSLog(@"Missing username or password for basic HTTP authentication challenge!");
			return;
		}
		
		// Create and respond with a user/password credential.
		NSURLCredential *credential = [NSURLCredential credentialWithUser:self.authenticationUserName password:self.authenticationPassword persistence:NSURLCredentialPersistenceForSession];
		[challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
	}
	else {
		NSLog(@"Unsupported authentication challenge type: %@", challenge.protectionSpace.authenticationMethod);
	}
}

@end
