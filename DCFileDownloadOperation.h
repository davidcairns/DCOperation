//
//  DCFileDownloadOperation.h
//
//  Created by David Cairns on 10/4/10.
//  Copyright 2010 David Cairns. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DCNetworkOperation.h"

extern NSString *DCFileDownloadErrorDomain;
enum {
	DCFileDownloadErrorCodeFileExists = 1, 
	DCFileDownloadErrorCodeCreationFailure, 
};

@interface DCFileDownloadOperation : DCNetworkOperation

- (id)initWithURLString:(NSString *)urlString destinationURL:(NSURL *)destinationURL;

@property(nonatomic, copy, readonly)NSURL *destinationURL;

@property(nonatomic, assign)long long bytesDownloaded;

@end
