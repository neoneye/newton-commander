/*
ExpectResult.h
direct port of rubys 'expect.rb' to objective c
by Simon Strandgaard on 26/04/11.
public domain or BSD license

requires CocoaOniguruma
http://limechat.net/cocoaoniguruma/
*/
#import <Foundation/Foundation.h>

@class OnigResult;

@interface ExpectResult : NSObject {
	NSString* m_buffer_string;
	OnigResult* m_onig_result;
}
@property (nonatomic, retain) NSString* bufferString;
@property (nonatomic, retain) OnigResult* onigResult;

@end
