//
//  DCFileDownloadOperation.h
//
//  Created by David Cairns on 10/4/10.
//  Copyright 2010 David Cairns. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DCNetworkOperation.h"

@interface DCFileDownloadOperation : DCNetworkOperation

- (id)initWithURLString:(NSString *)urlString destinationURL:(NSURL *)destinationURL context:(id)context;

@property(nonatomic, copy, readonly)NSURL *destinationURL;
@property(nonatomic, strong, readonly)id context;

@property(nonatomic, assign)long long bytesDownloaded;

@end
