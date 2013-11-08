//
//  exception.m
//  NCWorkerChild
//
//  Created by Simon Strandgaard on 05/06/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import "exception.h"
#import "Logger.h"

void handle_objc_exception(NSException* exception) {
	LOG_ERROR(@"exit! uncaught exception %@", exception);
	exit(EXIT_FAILURE);
}

void install_exception_handler() {
	NSSetUncaughtExceptionHandler(&handle_objc_exception);
}

void raise_test_exception() {
	[NSException raise:@"TEST EXCEPTION" format:@"this is a test"];
}
