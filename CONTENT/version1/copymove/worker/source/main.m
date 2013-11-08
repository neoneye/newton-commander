#import <Foundation/Foundation.h>
#import "CommandLineInterface.h"


NSArray* ArrayWithArguments(int argc, const char * argv[]) {
	NSMutableArray* ary = [NSMutableArray arrayWithCapacity:argc];
	for(int i=0; i<argc; i++) {
		[ary addObject:[[[NSString alloc] initWithUTF8String:argv[i]] autorelease]];
	}
	return [NSArray arrayWithArray:ary];
}

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	[CommandLineInterface runWithArguments:ArrayWithArguments(argc, argv)];

    [pool drain];
    return 0;
}
