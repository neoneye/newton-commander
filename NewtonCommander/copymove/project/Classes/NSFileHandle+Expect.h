/*
NSFileHandle+Expect.h
direct port of rubys 'expect.rb' to objective c
by Simon Strandgaard on 26/04/11.
public domain or BSD license

requires CocoaOniguruma
http://limechat.net/cocoaoniguruma/
*/
#import <Foundation/Foundation.h>


@class ExpectResult;

@interface NSFileHandle (Expect)

/*
wait for activity on the file descriptor.
stops waiting if it takes longer than X seconds.
*/
-(BOOL)waitForData:(float)seconds;


/*
buffer data on the filedescriptor until it matches the specified pattern.
*/
-(ExpectResult*)expect:(NSString*)pattern timeout:(float)seconds debug:(BOOL)debug;


/*
write to filedescriptor
*/
-(void)writeAsciiString:(NSString*)s;

@end
