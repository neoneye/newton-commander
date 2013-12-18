//
// exception.m
// Newton Commander
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "exception.h"
#import "NCLog.h"

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
