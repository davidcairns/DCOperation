//
//  DCOperation.m
//
//  Created by David Cairns on 9/9/10.
//  Copyright 2010 David Cairns. All rights reserved.
//

#import "DCOperation.h"
#import "DCOperation+ARCSupport.h"

@interface DCOperation ()
#if TARGET_OS_IPHONE
//@property(nonatomic, assign)UIBackgroundTaskIdentifier backgroundTaskId;
#endif

@property(nonatomic, assign)dispatch_semaphore_t synchronousExecutionSemaphore;

// A call to set the "executing" property to "YES".
- (void)startExecuting;
@end

NSString *DCOperationErrorDomain = @"DCOperationErrorDomain";

@implementation DCOperation
#if TARGET_OS_IPHONE
//@synthesize backgroundTaskId = _backgroundTaskId;
#endif
@synthesize timeoutInterval = _timeoutInterval;
@synthesize needsRunLoop = _needsRunLoop;
@synthesize responseDictionary = _responseDictionary;
@synthesize error = _error;
@synthesize synchronousExecutionSemaphore = _synchronousExecutionSemaphore;

- (id)init {
	if((self = [super init])) {
		self.responseDictionary = [NSMutableDictionary dictionary];
	}
	return self;
}
- (void)dealloc {
	DC_RELEASE(_responseDictionary);
	
	if(_synchronousExecutionSemaphore) {
		dispatch_release(_synchronousExecutionSemaphore);
	}
	
#if !defined(DC_USE_ARC)
	[super dealloc];
#endif
}

- (void)start {
	// Check to see if we've been cancelled before we've even begun.
	if(_isFinished || [self isCancelled]) {
		[self finish];
		return;
	}
	
	// Make sure that -start is running on the main thread.
	if(self.needsRunLoop && ![NSThread isMainThread]) {
		[self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
		return;
	}
	
	// Make sure that we should really start processing.
	if(![self operationShouldStart]) {
		[self finish];
	}
	
	// Start our timeout timer.
	if(self.timeoutInterval > 0.0) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, self.timeoutInterval * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
			if(!self.isFinished) {
				// Post a response that the operation timed out.
				self.error = [NSError errorWithDomain:DCOperationErrorDomain code:DCOperationErrorCodeTimeout userInfo:nil];
				
				// ... And clean up.
				[self finish];
			}
		});
	}
	
#if TARGET_OS_IPHONE && 0
	// Tell the application that we're about to start an operation that should still execute in the background.
	__block DCOperation *blockSelf = self;
	self.backgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^ {
		self.error = [NSError errorWithDomain:DCOperationErrorDomain code:DCOperationErrorCodeExpiration userInfo:nil];
		self.error.localizedDescription = NSLocalizedString(@"Execution timed out while running in the background.", @"Execution timed out while running in the background.");
		[blockSelf finish];
	}];
#endif
	
	[self startExecuting];
}
- (void)startAndWait {
	// Create our semaphore.
	self.synchronousExecutionSemaphore = dispatch_semaphore_create(0);
	
	// Start execution.
	[self start];
	
	// Wait for execution to finish.
	dispatch_semaphore_wait(self.synchronousExecutionSemaphore, DISPATCH_TIME_FOREVER);
}
- (void)startExecuting {
	[self willChangeValueForKey:@"isExecuting"];
	_isExecuting = YES;
	[self didChangeValueForKey:@"isExecuting"];
}
- (BOOL)operationShouldStart {
	// Default is just "YES".
	return YES;
}

- (BOOL)isConcurrent {
	return YES;
}
- (BOOL)isExecuting {
	return _isExecuting;
}
- (BOOL)isFinished {
	return _isFinished;
}

- (void)cancel {
	[super cancel];
	
	// Post a response that the operation was cancelled.
	NSMutableDictionary *errorUserInfo = [NSMutableDictionary dictionary];
	if(self.error) {
		[errorUserInfo setObject:self.error forKey:NSUnderlyingErrorKey];
	}
	self.error = [NSError errorWithDomain:DCOperationErrorDomain code:DCOperationErrorCodeCanceled userInfo:errorUserInfo];
	
	// ... And clean up.
	[self finish];
}

- (void)operationDidFinish {
	// Default is a no-op.
}
- (void)_reallyFinish {
	[self operationDidFinish];
	
	// Mark that we're finished.
	[self willChangeValueForKey:@"isFinished"];
	[self willChangeValueForKey:@"isExecuting"];
	_isFinished = YES;
	_isExecuting = NO;
	[self didChangeValueForKey:@"isExecuting"];
	[self didChangeValueForKey:@"isFinished"];
	
#if TARGET_OS_IPHONE
//	// Tell the application that we're done the background operation.
//	[[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskId];
//	self.backgroundTaskId = UIBackgroundTaskInvalid;
#endif
	
	// If our synchronous execution semaphore exists, signal it.
	if(self.synchronousExecutionSemaphore) {
		dispatch_semaphore_signal(self.synchronousExecutionSemaphore);
	}
}
- (void)finish {
	[self performSelectorOnMainThread:@selector(_reallyFinish) withObject:nil waitUntilDone:YES];
}

@end
