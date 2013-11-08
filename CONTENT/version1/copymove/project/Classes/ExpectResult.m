/*
ExpectResult.h
direct port of rubys 'expect.rb' to objective c
by Simon Strandgaard on 26/04/11.
public domain or BSD license

requires CocoaOniguruma
http://limechat.net/cocoaoniguruma/
*/
#import "ExpectResult.h"
#import "OnigRegexp.h"

@implementation ExpectResult

@synthesize bufferString = m_buffer_string;
@synthesize onigResult = m_onig_result;

-(void)dealloc {
	self.bufferString = nil;
	self.onigResult = nil;
	[super dealloc];
}

@end
