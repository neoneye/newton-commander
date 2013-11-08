/*********************************************************************
JFCopyTest.mm - Test the code for copying files

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#import "JFCopyTest.h"
#import "JFCopy.h"
#import "JFSystemCopyThread.h"

static const NSString* kJFCopyTestPath       = @"/tmp/juxtafile_test";
static const NSString* kJFCopyTestPathDest   = @"/tmp/juxtafile_test/dest";
static const NSString* kJFCopyTestPathSource = @"/tmp/juxtafile_test/src";

@interface JFCopyTest (Private)
-(void)ensureExistDir:(NSString*)pathToDir;
-(void)prepareTestdir;
@end

@implementation JFCopyTest

-(id)init {
	self = [super init];
    if(self) {
		m_copy = nil;   
		m_mainwindow = nil;
    }
    return self;
}

-(void)ensureExistDir:(NSString*)pathToDir {
	NSFileManager* fm = [NSFileManager defaultManager];
	BOOL isdir = NO;
	BOOL ok = [fm fileExistsAtPath:pathToDir isDirectory:&isdir];
	NSAssert(ok, @"a testdir must exist");
	NSAssert(isdir, @"the testdir must be a dir");
}

-(void)prepareTestdir {
	NSString* path_top = kJFCopyTestPath;
	NSString* path_src = kJFCopyTestPathSource;
	NSString* path_dst = kJFCopyTestPathDest;

	[self ensureExistDir:path_top];
	[self ensureExistDir:path_src];

	NSFileManager* fm = [NSFileManager defaultManager];
	BOOL isdir = NO;
	BOOL ok = [fm fileExistsAtPath:path_dst isDirectory:&isdir];
	if(ok) {
		NSError* err = nil;
		ok = [fm removeItemAtPath:path_dst error:&err];
		NSAssert(ok, @"couldn't remove destination dir for some reason");
	}
	{
		NSError* err = nil;
		ok = [fm createDirectoryAtPath:path_dst withIntermediateDirectories:NO attributes:nil error:&err];
		NSAssert(ok, @"couldn't create the destination dir for some reason");
	}
	
	// NSLog(@"%s testdir is good", _cmd);
}

-(void)applicationDidFinishLaunching:(NSNotification*)notification {
	[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self
		andSelector:@selector(handleQuitAppleEvent:withReplyEvent:)
		forEventClass:kCoreEventClass
		andEventID:kAEQuitApplication];

	[self prepareTestdir];


	NSArray* testdir_names1 = [NSArray arrayWithObjects:
		@"big2.txt",
		@"README.txt", 
		@"bigfile.txt",
	    nil
	];

	NSArray* testdir_names2 = [NSArray arrayWithObjects:
		@"a", 
		@"test", 
		@"big2.txt",
		@"abc", 
		@"x", 
		@"bxb", 
		@"y", 
		@"README.txt", 
		@"bigfile.txt",
		@"lsdkjfX",
	    nil
	];

	NSArray* testdir_names3 = [NSArray arrayWithObjects:
		@"a", 
		@"x", 
		@"y", 
		@"z", 
		@"test", 
		@"TesT2", 
		@"link_to_longer.txt", 
		@"a2", 
		@"big2.txt",
		@"A B C - wer",
		@"abc", 
		@"habc", 
		@"x", 
		@"bxb", 
		@"y", 
		@"README.txt", 
		@"hmain.cpp", 
		@"hlonger.txt", 
		@"muchlonger.txt", 
		@"longer.txt", 
		@"bigfile.txt",
		@"lsdkjfX",
		@"lsdkjf",
	    nil
	];

	NSArray* aopen_slow_ftp_server_names = [NSArray arrayWithObjects:
		@"AMDClock.exe", 
		@"procexp.exe", 
		// @"utility",
		@"minipc",
	    nil
	];
    

#if 0
	NSArray* copy_names = testdir_names1;
	NSString* source_dir = kJFCopyTestPathSource;
#endif
#if 0
	NSArray* copy_names = testdir_names2;
	NSString* source_dir = kJFCopyTestPathSource;
#endif
#if 1
	NSArray* copy_names = testdir_names3;
	NSString* source_dir = kJFCopyTestPathSource;
#endif
#if 0
	NSArray* copy_names = aopen_slow_ftp_server_names;
	NSString* source_dir = @"/Volumes/ftp.aopen.com.cn/pub01";
#endif

#if 0
	JFSystemCopyThread* syscopy = [[JFSystemCopyThread alloc] init];
	[syscopy setSourceDir:kJFCopyTestPathSource];
	[syscopy setTargetDir:kJFCopyTestPathDest];
	[syscopy setNames:testdir_names];
	[syscopy start];
	exit(0);
#endif	

	m_copy = [[JFCopy alloc] init];
	[m_copy load];
	[m_copy fillWithDummyData:self];

	
	[m_copy setSourcePath:source_dir];
	[m_copy setTargetPath:kJFCopyTestPathDest];
	[m_copy setNames:copy_names];


	[self showSheetAction:self];
}

-(void)handleQuitAppleEvent:(NSAppleEventDescriptor*)event
withReplyEvent:(NSAppleEventDescriptor*)replyEvent
{
	[self quitAction:nil];
}

-(IBAction)quitAction:(id)sender {
	// end all active sheets
	for (NSWindow *win in [NSApp windows])
		if ([win attachedSheet])
			[NSApp endSheet:[win attachedSheet]];
	[NSApp terminate:nil];
}

-(IBAction)showSheetAction:(id)sender {
	NSAssert(m_copy, @"copy must be initialized at this point");
	NSAssert(m_mainwindow, @"MainMenu.nib must initialize m_mainwindow");
	[m_copy beginSheetForWindow:m_mainwindow];
}

@end

int main(int argc, char** argv) {
    return NSApplicationMain(argc, (const char **)argv);
}
