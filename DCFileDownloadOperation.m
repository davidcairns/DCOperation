//
//  DCFileDownloadOperation.m
//
//  Created by David Cairns on 10/4/10.
//  Copyright 2010 David Cairns. All rights reserved.
//

#import "DCFileDownloadOperation.h"
#import "DCOperation+ARCSupport.h"

NSString *DCFileDownloadErrorDomain = @"DCFileDownloadErrorDomain";

@interface DCFileDownloadOperation()
@property(nonatomic, copy)NSURL *destinationURL;
@end

@implementation DCFileDownloadOperation
@synthesize destinationURL = _destinationURL;
@synthesize bytesDownloaded = _bytesDownloaded;

- (id)initWithURLString:(NSString *)urlString destinationURL:(NSURL *)destinationURL {
	if((self = [super init])) {
		NSAssert(urlString, @"Attempted to download from nil url.");
		
		self.urlString = urlString;
		self.destinationURL = destinationURL;
		
		// This operation should not worry about timeout.
		self.timeoutInterval = 0.0;
	}
	return self;
}
- (void)dealloc {
	DC_RELEASE(_destinationURL);
	
#if !defined(DC_USE_ARC)
	[super dealloc];
#endif
}

- (BOOL)operationShouldStart {
	// Generate the path for this language pack archive.
	NSFileManager *fileManager = DC_AUTORELEASE([[NSFileManager alloc] init]);
	
	// If it exists, delete the pre-existing archive file.
	NSError *error = nil;
	BOOL isDirectory = NO;
	NSString *filePath = [self.destinationURL absoluteString];
	if([fileManager fileExistsAtPath:filePath isDirectory:&isDirectory]) {
		if(isDirectory) {
			NSLog(@"Expected: old language pack; found: directory. Deleting anyway...");
		}
		
		// Attempt to delete the file.
		if(![fileManager removeItemAtPath:filePath error:&error]) {
			self.error = [NSError errorWithDomain:DCFileDownloadErrorDomain code:DCFileDownloadErrorCodeFileExists userInfo:nil];
			return NO;
		}
	}
	
	// Create the file we're to write into.
	if(![fileManager createFileAtPath:filePath contents:[NSData data] attributes:nil]) {
		self.error = [NSError errorWithDomain:DCFileDownloadErrorDomain code:DCFileDownloadErrorCodeCreationFailure userInfo:nil];
		return NO;
	}
	
	return [super operationShouldStart];
}

- (void)finish {
	NSLog(@"Downloaded file stored in : %@", self.destinationURL);
	
	[super finish];
}

// Override the NSURLConnection delegate method.
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	// We've received some data; append it to our file.
	NSError *error = nil;
	NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingToURL:self.destinationURL error:&error];
	[fileHandle seekToEndOfFile];
	[fileHandle writeData:data];
	
	self.bytesDownloaded += [data length];
	
	// Make sure the transfer update block still gets called.
	if(self.transferUpdateBlock) {
		self.transferUpdateBlock();
	}
}

@end
