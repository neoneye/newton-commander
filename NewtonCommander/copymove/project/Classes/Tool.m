//
//  Tool.m
//  project
//
//  Created by Simon Strandgaard on 23/04/11.
//  Copyright 2011 opcoders.com. All rights reserved.
//

/*

oniguruma
http://limechat.net/cocoaoniguruma/
http://www.geocities.jp/kosako3/oniguruma/doc/RE.txt

libexpect
http://sourceforge.net/projects/expect/
http://expect.sourceforge.net/


expect.rb
http://www.ruby-forum.com/topic/125676#557824

def expect(pat,timeout=9999999)
  buf = ''
  case pat
  when String
    e_pat = Regexp.new(Regexp.quote(pat))
  when Regexp
    e_pat = pat
  end
  while true
    if IO.select([self],nil,nil,timeout).nil? then
      result = nil
      break
    end
    c = getc.chr
    buf << c
    if $expect_verbose
      STDOUT.print c
      STDOUT.flush
    end
    if mat=e_pat.match(buf) then
      result = [buf,*mat.to_a[1..-1]]
      break
    end
  end
  if block_given? then
    yield result
  else
    return result
  end
  nil
end

*/

#import "Tool.h"
#import "NSFileHandle+Expect.h"
#import "OnigRegexp.h"
#import "ExpectResult.h"



@interface Tool ()
@end

@implementation Tool

@synthesize task = m_task;
@synthesize readHandle = m_read_handle;
@synthesize writeHandle = m_write_handle;

-(id)init {
	if(self = [super init]) {
	}
	return self;
}


-(void)start {

	NSArray* arguments = [NSArray arrayWithObjects:
		@"/Users/neoneye/git/Commander/CONTENT/version1/copymove/script/copymove_tool.rb",
		nil
	];

	NSTask* task = [[[NSTask alloc] init] autorelease];
	[task setLaunchPath:@"/usr/bin/ruby"];
	// [task setLaunchPath:@"/bin/echo"];

    NSPipe* readPipe = [NSPipe pipe];
    NSPipe* writePipe = [NSPipe pipe];

    [task setStandardInput: writePipe];
    [task setStandardOutput: readPipe];
    [task setArguments:arguments];

    [task launch];

	self.task = task;
	self.readHandle = [readPipe fileHandleForReading];
	self.writeHandle = [writePipe fileHandleForWriting];

}

-(void)stop {	
    self.readHandle = nil;
    self.writeHandle = nil;
    self.task = nil;
}

-(ExpectResult*)expect:(NSString*)pattern {
	return [self.readHandle expect:pattern timeout:1 debug:NO];
}

-(void)write:(NSString*)s {
    [self.writeHandle writeAsciiString:s];	
}



@end
