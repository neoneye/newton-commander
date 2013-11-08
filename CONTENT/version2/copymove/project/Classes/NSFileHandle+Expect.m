/*
NSFileHandle+Expect.m
direct port of rubys 'expect.rb' to objective c
by Simon Strandgaard on 26/04/11.
public domain or BSD license

requires CocoaOniguruma
http://limechat.net/cocoaoniguruma/
*/
#import "NSFileHandle+Expect.h"
#import "OnigRegexp.h"
#import "ExpectResult.h"


@implementation NSFileHandle (Expect)

-(BOOL)waitForData:(float)seconds {
    struct timeval t; 
	t.tv_sec = (int)seconds;
	float remain = seconds - t.tv_sec;
	t.tv_usec = (int)(remain * 1000000);

	
	int fd = [self fileDescriptor];
    fd_set ready; 
    FD_ZERO(&ready); 
    FD_SET((unsigned int)fd, &ready); 

    int res = select(fd+1, &ready, NULL, NULL, &t); 
	if(res == 0) {
		return NO; // timeout
	}
    if(FD_ISSET(fd, &ready)) {
		return YES; // we have data, one or more bytes is ready
	}
	return NO; // error
}


-(ExpectResult*)expect:(NSString*)pattern timeout:(float)seconds debug:(BOOL)debug {
	OnigRegexp* regexp = [OnigRegexp compile:pattern];
    NSMutableString* buffer = [NSMutableString stringWithCapacity:100];
	ExpectResult* result = nil;
	while(1) {
		// wait until 1 byte is ready
		if(![self waitForData:seconds]) {
			// timeout or error
			result = nil;
			break;
		}
		
		// read out the byte and append it to the buffer
		NSData* char_data = [self readDataOfLength:1];
	    NSString* char_string = [[NSString alloc] initWithData:char_data encoding: NSASCIIStringEncoding];
        [buffer appendString:char_string];
		if(debug) {
			NSLog(@"%s %@", _cmd, char_string);
		}
		[char_string release];

		// see if the new buffer now satisfies the pattern
		OnigResult* r = [regexp search:buffer];
		if(r) {
			result = [[[ExpectResult alloc] init] autorelease];
			result.bufferString = [NSString stringWithString:buffer];
			result.onigResult = r;
			break;
		}
	}
	
	return result;
}

-(void)writeAsciiString:(NSString*)s {
    [self writeData:[s dataUsingEncoding:NSASCIIStringEncoding]];	
}

@end
