//
//  DCFileDownloadOperation.m
//
//  Created by David Cairns on 10/4/10.
//  Copyright 2010 David Cairns. All rights reserved.
//

#import "DCFileDownloadOperation.h"
#import "DCOperation+ARCSupport.h"

@interface DCFileDownloadOperation()
@property(nonatomic, copy)NSURL *destinationURL;
@property(nonatomic, strong)id context;
@end

@implementation DCFileDownloadOperation
@synthesize destinationURL = _destinationURL;
@synthesize context = _context;
@synthesize bytesDownloaded = _bytesDownloaded;

- (id)initWithURLString:(NSString *)urlString destinationURL:(NSURL *)destinationURL context:(id)context {
	if((self = [super init])) {
		NSAssert(urlString, @"Attempted to download from nil url.");
		NSAssert(context, @"Attempted to download language pack for nil product identifier.");
		
		self.urlString = urlString;
		self.destinationURL = destinationURL;
		self.context = context;
		
		// This operation should not worry about timeout.
		self.timeoutInterval = 0.0;
	}
	return self;
}
- (void)dealloc {
	DC_RELEASE(_destinationURL);
	DC_RELEASE(_context);
	
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
			[self.responseDictionary setValue:[NSDictionary dictionaryWithObjectsAndKeys:
											   @"type", @"ARCHIVE_EXISTS", 
											   @"msg", @"Could not overwrite pre-existing archive.", 
											   @"error", error, 
											   nil] 
									   forKey:DCResponseErrorKey];
			return NO;
		}
	}
	
	// Create the file we're to write into.
	if(![fileManager createFileAtPath:filePath contents:[NSData data] attributes:nil]) {
		[self.responseDictionary setValue:[NSDictionary dictionaryWithObjectsAndKeys:
										   @"type", @"CANNOT_CREATE_FILE", 
										   @"msg", @"Could not create archive file.", 
										   nil] 
								   forKey:DCResponseErrorKey];
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
