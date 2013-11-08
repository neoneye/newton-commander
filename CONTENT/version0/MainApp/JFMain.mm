/*********************************************************************
JFMain.mm - first code executed when the program is launched

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>

HACK: to provide immediate feedback to the user, 
we show a fake window within main(). It's a bit ugly,
however it allows us to provide feedback after 85 msec.
Where if we didn't have any fake window we would have
to wait 320 msec, because loading the MainWindow.nib
takes a lot of time. This timing info is measured on
my MacMini 1.8 GHz.

*********************************************************************/
#import "JFMain.h"

#define WINDOW_TOOLBAR_HEIGHT 55

namespace {

NSWindow* g_main_window = nil;

float g_enter_main_time = 100000;
float g_middle_main_time = 100000;
float g_endof_main_time = 100000;

float seconds_since_program_start() { 
	return ( (float)clock() / (float)CLOCKS_PER_SEC );
}

} // namespace

@interface JFMain (Private)
-(void)loadCoreBundle;
@end

@implementation JFMain

-(id)init {
    self = [super init];
	if(self) {
		m_core = nil;
	}
    return self;
}

-(void)applicationDidFinishLaunching:(NSNotification*)notification {

	[self performSelector: @selector(initEverything)
	           withObject: nil
	           afterDelay: 0.0];
}

-(void)initEverything {
	float t0 = seconds_since_program_start();
	[self loadCoreBundle];
	float t1 = seconds_since_program_start();
	[m_core initAppDelegate];
	[m_core setBookmarkMenu:m_bookmarks_menu];
	[m_core start];
	float t2 = seconds_since_program_start();

	// get rid of the fake main window that we opened within main
	[g_main_window setOneShot:YES];
	[g_main_window setReleasedWhenClosed:YES];
	[g_main_window close];
	g_main_window = nil;

	if(0) {
		NSLog(@"Enter main at %.3f seconds", g_enter_main_time);
		NSLog(@"Middle main at %.3f seconds", g_middle_main_time);
		NSLog(@"End of main at %.3f seconds", g_endof_main_time);
		NSLog(@"App start at %.3f seconds", t0);
		NSLog(@"Bundle load at %.3f seconds", t1);
		NSLog(@"Core start at %.3f seconds", t2);
	}
}

-(void)loadCoreBundle {
	NSAssert(m_core == nil, @"core must not be already initialized");
	
	NSString* bundle_name = @"JFCore.bundle";
	
	NSBundle* our_bundle = [NSBundle bundleForClass:[self class]];
	NSAssert(our_bundle, @"cannot find our bundle");
	NSString* resource_path = [our_bundle resourcePath];
	NSString* path = [resource_path stringByAppendingPathComponent:bundle_name];


	NSBundle* bundle = [NSBundle bundleWithPath:path];
	if(!bundle) {
		NSLog(@"ERROR: failed to load bundle at path=%@", path);
		return;
	}
	Class principal_class = [bundle principalClass];
	if(!principal_class) {
		NSLog(@"ERROR: no principalClass", _cmd);
		return;
	}

    if([principal_class
        conformsToProtocol:@protocol(JFCoreProtocol)] == NO) {
		NSLog(@"ERROR: doesn't conform");
		return;
	}

	m_core = [[principal_class alloc] init];
}

-(IBAction)reloadTab:(id)sender {
	[m_core reloadTab:sender];
}

-(IBAction)swapTabs:(id)sender {
	[m_core swapTabs:sender];
}

-(IBAction)mirrorTabs:(id)sender {
	[m_core mirrorTabs:sender];
}

-(IBAction)cycleInfoPanes:(id)sender {
	[m_core cycleInfoPanes:sender];
}

-(IBAction)revealInFinder:(id)sender {
	[m_core revealInFinder:sender];
}

-(IBAction)revealInfoInFinder:(id)sender {
	[m_core revealInfoInFinder:sender];
}

-(IBAction)selectCenterRow:(id)sender {
	[m_core selectCenterRow:sender];
}

-(IBAction)renameAction:(id)sender {
	[m_core renameAction:sender];
}

-(IBAction)mkdirAction:(id)sender {
	[m_core mkdirAction:sender];
}

-(IBAction)mkfileAction:(id)sender {
	[m_core mkfileAction:sender];
}

-(IBAction)deleteAction:(id)sender {
	[m_core deleteAction:sender];
}

-(IBAction)moveAction:(id)sender {
	[m_core moveAction:sender];
}

-(IBAction)newCopyAction:(id)sender {
	[m_core newCopyAction:sender];
}

-(IBAction)betterCopyAction:(id)sender {
	[m_core betterCopyAction:sender];
}

-(IBAction)copyAction:(id)sender {
	[m_core copyAction:sender];
}

-(IBAction)helpAction:(id)sender {
	[m_core helpAction:sender];
}

-(IBAction)viewAction:(id)sender {
	[m_core viewAction:sender];
}

-(IBAction)editAction:(id)sender {
	[m_core editAction:sender];
}

-(IBAction)changeFontSizeAction:(id)sender {
	[m_core changeFontSizeAction:sender];
}

-(IBAction)restartDiscoverTaskAction:(id)sender {
	[m_core restartDiscoverTaskAction:sender];
}

-(IBAction)forceCrashDiscoverTaskAction:(id)sender {
	[m_core forceCrashDiscoverTaskAction:sender];
}

-(IBAction)hideShowDiscoverStatWindowAction:(id)sender {
	[m_core hideShowDiscoverStatWindowAction:sender];
}

-(IBAction)hideShowReportStatWindowAction:(id)sender {
	[m_core hideShowReportStatWindowAction:sender];
}

-(IBAction)debugInspectCacheAction:(id)sender {
	[m_core debugInspectCacheAction:sender];
}

-(IBAction)debugSeparatorAction:(id)sender {
	[m_core debugSeparatorAction:sender];
}

-(IBAction)debugAction:(id)sender {
	[m_core debugAction:sender];
}

-(IBAction)selectAllAction:(id)sender {
	[m_core selectAllAction:sender];
}

-(IBAction)selectNoneAction:(id)sender {
	[m_core selectNoneAction:sender];
}

-(IBAction)selectAllOrNoneAction:(id)sender {
	[m_core selectAllOrNoneAction:sender];
}

-(IBAction)invertSelectionAction:(id)sender {
	[m_core invertSelectionAction:sender];
}

-(IBAction)copyCurrentPathStringToClipboardAction:(id)sender {
	[m_core copyCurrentPathStringToClipboardAction:sender];
}

-(IBAction)openDiffToolAction:(id)sender {
	[m_core openDiffToolAction:sender];
}

-(IBAction)openCurrentPathInTerminalAction:(id)sender {
	[m_core openCurrentPathInTerminalAction:sender];
}

-(IBAction)showReportAction:(id)sender {
	[m_core showReportAction:sender];
}

-(IBAction)installCommandlineToolAction:(id)sender {
	[m_core installCommandlineToolAction:sender];
}

-(IBAction)installKCHelperAction:(id)sender {
	[m_core installKCHelperAction:sender];
}

-(IBAction)launchDiscoverAction:(id)sender {
	[m_core launchDiscoverAction:sender];
}

-(IBAction)showPreferencesPanel:(id)sender {
	[m_core showPreferencesPanel:sender];
}

-(IBAction)showBookmarkPreferencesPanel:(id)sender {
	[m_core showBookmarkPreferencesPanel:sender];
}

-(IBAction)showAboutPanel:(id)sender {
	[m_core showAboutPanel:sender];
}

-(IBAction)donateMoneyAction:(id)sender {
	[m_core donateMoneyAction:sender];
}

-(IBAction)visitWebsiteAction:(id)sender {
	[m_core visitWebsiteAction:sender];
}

-(void)application:(NSApplication*)sender openFiles:(NSArray*)filenames {
	/*
	TODO: this function is invoked before
	the core is loaded, which makes this
	function have no effect.
	It only works when the core is loaded.
	solution would be to put the files in a queue
	and when the core has been loaded.. then open them.
	*/
	[m_core application:sender openFiles:filenames];
}

@end


int main(int argc, char** argv) {
	g_enter_main_time = seconds_since_program_start();

	[[NSAutoreleasePool alloc] init];

	/*
	make it appear as if the program starts up much faster.
	On my MacMini this window can be shown after 80 msec.
	Where if I had to wait for the MainWindow.nib then it
	would take 320 msec.
	*/
	{
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		[NSApplication sharedApplication];

		NSUInteger style = NSMiniaturizableWindowMask | NSResizableWindowMask | NSTexturedBackgroundWindowMask;

		NSWindow* w = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 500, 400) styleMask:style backing:NSBackingStoreBuffered defer:YES];
		NSColor* color = [NSColor colorWithCalibratedWhite:0.55 alpha:0.8];
		[w setBackgroundColor:color];
		[w setOpaque:NO];
		g_middle_main_time = seconds_since_program_start();

		[w center];
		BOOL ok = [w setFrameUsingName:@"MainWindow"];
		// NSLog(@"is ok: %i", ok);
		
		// correct height, since its not stored in preferences
		{
			NSRect f = [w frame];
			f.origin.y -= WINDOW_TOOLBAR_HEIGHT;
			f.size.height += WINDOW_TOOLBAR_HEIGHT;
			[w setFrame:f display:NO];
		}

/*		{ // doesn't help make it look any prettier
			NSRect f = [w frame];
			NSRect r = NSMakeRect(
				NSWidth(f) / 2 - 40,
				NSHeight(f) / 2 - 40,
				80,
				80
			);
			NSProgressIndicator* pi = [[NSProgressIndicator alloc] initWithFrame:r];
			[pi setStyle:NSProgressIndicatorSpinningStyle];
			[[w contentView] addSubview:pi];
			[pi startAnimation:nil];
			[pi release];
		}/**/

	  	[w makeKeyAndOrderFront:nil];
	
		g_main_window = [w retain];

		g_endof_main_time = seconds_since_program_start();


		// sleep(3);
		[pool release];
	}

    return NSApplicationMain(argc,  (const char **) argv);
}
