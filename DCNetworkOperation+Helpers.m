/*
 *  DCNetworkOperation+Helpers.m
 *
 *  Created by David Cairns on 1/24/11.
 *  Copyright 2011 David Cairns. All rights reserved.
 *
 */

#include "DCNetworkOperation+Helpers.h"

NSString *DCFileTransferBoundary() {
	return @"---------------------------14921776200120102063111419849";
}
NSString *DCHeaderFieldForFileTransfer() {
	return [NSString stringWithFormat:@"multipart/form-data; boundary=%@", DCFileTransferBoundary()];
}

NSData *DCDataWithFileAndParamName(NSString *filename, NSString *paramName) {
	NSMutableData *data = [NSMutableData data];
	[data appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", DCFileTransferBoundary()] dataUsingEncoding:NSUTF8StringEncoding]];
	[data appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", paramName, filename] dataUsingEncoding:NSUTF8StringEncoding]];
	[data appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[data appendData:[NSData dataWithContentsOfFile:filename]];
	[data appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", DCFileTransferBoundary()] dataUsingEncoding:NSUTF8StringEncoding]];
	return data;
}

NSData *DCDataForValueAndParamName(NSString *value, NSString *paramName) {
	NSMutableData *data = [NSMutableData data];
	[data appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", DCFileTransferBoundary()] dataUsingEncoding:NSUTF8StringEncoding]];
	NSString *str = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n%@", paramName, value];
	[data appendData:[str dataUsingEncoding:NSUTF8StringEncoding]];
	[data appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", DCFileTransferBoundary()] dataUsingEncoding:NSUTF8StringEncoding]];
	return data;
}
