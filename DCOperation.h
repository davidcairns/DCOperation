//
//  DCOperation.h
//
//  Created by David Cairns on 9/9/10.
//  Copyright 2010 David Cairns. All rights reserved.
//

#import <Foundation/Foundation.h>

// Response dictionary entries.
extern NSString *DCResponseErrorKey;

typedef enum {
	DCOperationErrorTimeout, 
	DCOperationErrorConnection, 
} DCOperationErrorType;

@interface DCOperation : NSOperation {
	BOOL _isFinished;
	BOOL _isExecuting;
}

@property(nonatomic, assign)NSTimeInterval timeoutInterval;
@property(nonatomic, assign)BOOL needsRunLoop;

@property(nonatomic, strong)NSMutableDictionary *responseDictionary;

// Runs the operation synchronously. As opposed to -start.
- (void)startAndWait;

// A call to manually finish the operation; should really only be called by subclasses.
- (void)finish;

// Subclasses may use this to do operation set up.
- (BOOL)operationShouldStart;
// Subclasses may override to clean up immediately after processing is over.
- (void)operationDidFinish;

@end
