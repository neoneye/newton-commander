/*********************************************************************
AppDelegate.mm - the control center for the entire program

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/
#include "AppDelegate.h"
#include "NSImage+QuickLook.h"
#include "OFMPane.h"
#include "OFMTableView.h"
#include "KCDiscoverStatistics.h"
#include "KCDiscover.h"
#include "KCReportStatistics.h"
#include "KCReport.h"
#include "DirCache.h"
#include "KCCopySheet.h"

#include "system_GDE.h"

#include "PanelTable.h"

#include <SecurityFoundation/SFAuthorization.h>
#include <ctime>
#include <fts.h>
// #include <sys/types.h>
// #include <sys/dirent.h>
#include <sys/stat.h>
#include <assert.h>
#include <Carbon/Carbon.h>

#include "BetterAuthorizationSampleLib.h"
#include "KCHelperCommon.h"


#include <sys/param.h>
#include <sys/mount.h>


/*#ifndef __BSD_VISIBLE
# define __BSD_VISIBLE
#endif */
// #include <dirent.h>
// extern "C" DIR *__opendir2(const char *name, int flags);


#import "MBPreferencesController.h"
#import "JFGeneralPrefController.h"
#import "JFActionPrefController.h"
#import "JFBookmarkPrefController.h"
#import "JFIgnorePrefController.h"
#import "JFActionMenu.h"
#import "JFBookmarkMenu.h"

#import "JFCoreProtocol.h"
#import "JFCopy.h"
#import "JFMainWindow.h"


static AuthorizationRef gAuth;
static BOOL g_install_mode;

namespace {

float seconds_since_program_start() { 
	return ( (float)clock() / (float)CLOCKS_PER_SEC );
}

} // namespace


NSString* opcoders_show_discover_stat_window = @"Opcoders Show Discover Statistics Window";
NSString* opcoders_show_report_stat_window = @"Opcoders Show Report Statistics Window";


NSString* opcoders_filter_left_panel_toolbar_item_identifier = @"Opcoders Filter Left Panel Toolboar Item";
NSString* opcoders_filter_right_panel_toolbar_item_identifier = @"Opcoders Filter Right Panel Toolboar Item";
NSString* opcoders_help_toolbar_item_identifier = @"Opcoders Help Toolboar Item";
NSString* opcoders_menu_toolbar_item_identifier = @"Opcoders Menu Toolboar Item";
NSString* opcoders_view_toolbar_item_identifier = @"Opcoders View Toolboar Item";
NSString* opcoders_edit_toolbar_item_identifier = @"Opcoders Edit Toolboar Item";
NSString* opcoders_copy_toolbar_item_identifier = @"Opcoders Copy Toolboar Item";
NSString* opcoders_move_toolbar_item_identifier = @"Opcoders Move Toolboar Item";
NSString* opcoders_mkdir_toolbar_item_identifier = @"Opcoders MakeDir Toolboar Item";
NSString* opcoders_delete_toolbar_item_identifier = @"Opcoders Delete Toolboar Item";


/*********************************************************************


*********************************************************************/



class MyGetDirEntries : public SystemGetDirEntries {
private:
	NSMutableArray* m_filenames;

public:
	MyGetDirEntries() : m_filenames(nil) {
		m_filenames = [NSMutableArray arrayWithCapacity:10000];
	}
	
	NSArray* get_filenames() {
		return [[m_filenames copy] autorelease];
	}
	
	void process_error() {
		// nothing
	}

	void process_dirent(
		unsigned long long d_inode,
		u_int16_t d_reclen,
		u_int8_t d_type,
		u_int8_t d_namlen,
		const char* d_name,
		const char* pretty_d_type)
	{
		NSString* filename = [NSString stringWithUTF8String:d_name];
		[m_filenames addObject:filename];
	}
};


/*********************************************************************


*********************************************************************/





/* 
RegisterMyHelpBook registers an application's help
book.  It can be called as part of the application's
initialization sequence.  Once it has been called, the
application is free to use any of the other Apple Help
routines to access and display the contents of their
help book.

This routine illustrates how one would use the
AHRegisterHelpBook routine in their application.
*/
OSStatus register_my_help_book() {
    CFBundleRef myAppsBundle;
    CFURLRef myBundleURL;
    FSRef myBundleRef;
    OSStatus err;

        /* set up a known state */
    myAppsBundle = NULL;
    myBundleURL = NULL;

        /* Get our application's main bundle
        from Core Foundation */
    myAppsBundle = CFBundleGetMainBundle();
    if (myAppsBundle == NULL) { err = fnfErr; goto bail;}

        /* retrieve the URL to our bundle */
    myBundleURL = CFBundleCopyBundleURL(myAppsBundle);
    if (myBundleURL == nil) { err = fnfErr; goto bail;}

        /* convert the URL to a FSRef */
    if ( ! CFURLGetFSRef(myBundleURL, &myBundleRef) ) {
        err = fnfErr;
        goto bail;
    }

        /* register our application's help book */
    err = AHRegisterHelpBook(&myBundleRef);
    if (err != noErr) goto bail;

        /* done */
    CFRelease(myBundleURL);
    return noErr;

bail:
    if (myBundleURL != NULL) CFRelease(myBundleURL);
    return err;
}



/*********************************************************************


*********************************************************************/





@interface AppDelegate (Private)

- (IBAction)doGetVersion:(id)sender;
- (IBAction)doLaunchDiscover:(id)sender;

-(OFMPane*)activePane;
-(OFMPane*)inactivePane;

-(void)syncFontSettings;
-(void)jumpToLocationIndex:(int)index;
-(void)reloadPathControls;
-(void)reloadLeft;   
-(void)reloadRight;
-(void)reloadWindowTitle;
-(void)reloadQuickLook;
-(void)renameFromPath:(NSString*)src_path toPath:(NSString*)dest_path;
-(void)syncWithSearchField;
-(void)maybeShowDiscoverStatWindow;
-(void)maybeShowReportStatWindow;
-(void)locateDiscoverAppExecutable;
-(void)locateReportAppExecutable;
-(void)locateCopyAppExecutable;
-(void)runAppleScript:(NSString*)script arguments:(NSArray*)arguments;
-(void)waitUntilNoKeysArePressed;
-(void)terminalNewTabWithDir:(NSString*)dir_to_open;
-(void)terminalNewWindowWithDir:(NSString*)dir_to_open;
-(void)terminalSetToDir:(NSString*)dir_to_open;

-(void)dumpVolumeInfoForPath:(NSString*)pathToFile;

-(void)customizeActionMenu;
-(void)customizeBookmarkMenu;

@end

@implementation AppDelegate

- (id)init {
    self = [super init];
	if(self) {
		// NSLog(@"sizeof(FileTableItem): %i", (int)sizeof(FileTableItem));

		m_left_pane = [[OFMPane alloc] initWithName:@"Left"];
		m_right_pane = [[OFMPane alloc] initWithName:@"Right"];
		
		[m_left_pane setDelegate:self];
		[m_right_pane setDelegate:self];
		
		m_left_discover = nil;
		m_right_discover = nil;

		m_report = nil;
		
		m_alert = nil;
		m_mkdir_location = nil;
		m_mkfile_location = nil;
		m_move_src_location = nil;
		m_copy_src_location = nil;
		
		m_table_font_size = 12;

		m_path_to_discover_app_executable = nil;
		m_path_to_report_app_executable = nil;
		m_path_to_copy_app_executable = nil;
		
		m_report_stat_item = nil;
		m_time_report_begin = 0;
		m_time_report_processing = 0;
		
		m_transaction_id_seed = 0;
		
		m_copy = nil;
		
		m_toolbar_item1 = nil;
		m_toolbar_item7 = nil;
	}
    return self;
}

-(void)start {
	[self setupAuth];

	g_install_mode = (GetCurrentKeyModifiers() & cmdKey) != 0;

	[self applicationWillFinishLaunching:nil];
	[self applicationDidFinishLaunching:nil];
}

-(void)setupAuth {
	/*
	TODO: clean up global variable crap, which is remains from 
	having them in the main.mm.. but because of refactoring
	into a class this is a quickndirty hack to make it compile
	asap. of course this should be fixed.
	*/
	g_install_mode = NO;
	// maybe_user_wants_to_install();
	

    OSStatus    junk;
    
    // Create the AuthorizationRef that we'll use through this application.  We ignore 
    // any error from this.  A failure from AuthorizationCreate is very unusual, and if it 
    // happens there's no way to recover; Authorization Services just won't work.

    junk = AuthorizationCreate(NULL, NULL, kAuthorizationFlagDefaults, &gAuth);
    assert(junk == noErr);
    assert(gAuth != NULL);



	// For each of our commands, check to see if a right specification exists and, if not,
    // create it.
    //
    // The last parameter is the name of a ".strings" file that contains the localised prompts 
    // for any custom rights that we use.
    
	BASSetDefaultRules(
		gAuth, 
		kKCHelperCommandSet, 
		CFBundleGetIdentifier(CFBundleGetMainBundle()), 
		CFSTR("KCHelperAuthorizationPrompts")
	);
}

-(void)setBookmarkMenu:(NSMenu*)menu {
	// NSLog(@"%s", _cmd);
	[[JFBookmarkMenu shared] setMenu:menu];
}

-(IBAction)installKCHelperAction:(id)sender {
	NSLog(@"%s", _cmd);

    BASFailCode     failCode;
	OSStatus err;

    NSString *      bundleID;
    
    bundleID = [[NSBundle mainBundle] bundleIdentifier];
    assert(bundleID != NULL);


    int alertResult = NSRunAlertPanel(@"Needs Install", @"BAS needs to install", @"Install", @"Cancel", NULL);
    
    if ( alertResult == NSAlertDefaultReturn ) {
        // Try to fix things.
        
        err = BASFixFailure(gAuth, (CFStringRef) bundleID, CFSTR("InstallKCHelper"), CFSTR("KCHelper"), failCode);

        // If the fix went OK, retry the request.
        
        if (err == noErr) {
			NSLog(@"%s OK installed it", _cmd);
        } else {
			NSLog(@"%s failed to install", _cmd);
		}
    } else {
        err = userCanceledErr;
    }

}

-(IBAction)launchDiscoverAction:(id)sender {
	NSLog(@"%s", _cmd);
	[self doGetVersion:self];
	[self doLaunchDiscover:self];
}

- (IBAction)doGetVersion:(id)sender
    // Called when the user clicks the "GetVersion" button.  This is the simplest 
    // possible BetterAuthorizationSample operation, in that it doesn't handle any failures.
{
    OSStatus        err;
    NSString *      bundleID;
    NSDictionary *  request;
    CFDictionaryRef response;

    response = NULL;
    
    // Create our request.  Note that NSDictionary is toll-free bridged to CFDictionary, so 
    // we can use an NSDictionary as our request.  Also, if the "Force failure" checkbox is 
    // checked, we use the wrong command ID to deliberately cause an "unknown command" error 
    // so that we can test that code path.
    
    request = [NSDictionary dictionaryWithObjectsAndKeys:@kKCHelperGetVersionCommand, @kBASCommandKey, nil];
    assert(request != NULL);
    
    bundleID = [[NSBundle mainBundle] bundleIdentifier];
    assert(bundleID != NULL);
    
    // Execute it.
    
	err = BASExecuteRequestInHelperTool(
        gAuth, 
        kKCHelperCommandSet, 
        (CFStringRef) bundleID, 
        (CFDictionaryRef) request, 
        &response
    );
    
    // If the above went OK, it means that the IPC to the helper tool worked.  We 
    // now have to check the response dictionary to see if the command's execution 
    // within the helper tool was successful.  For the GetVersion command, this 
    // is unlikely to ever fail, but we should still check. 
    
    if (err == noErr) {
        err = BASGetErrorFromResponse(response);
    }
    
    // Log our results.
    
    if (err == noErr) {
		NSLog(@"%s version = %@", _cmd, [(NSDictionary *)response objectForKey:@kKCHelperGetVersionResponse]);
    } else {
		NSLog(@"%s Failed with error %ld.", _cmd, (long) err);
    }
    
    if (response != NULL) {
        CFRelease(response);
    }
}

- (IBAction)doLaunchDiscover:(id)sender
    // Called when the user clicks the "GetUIDs" button.  This is a typical BetterAuthorizationSample 
    // privileged operation implemented in Objective-C.
{
    OSStatus        err;
    BASFailCode     failCode;
    NSString *      bundleID;
    NSDictionary *  request;
    CFDictionaryRef response;

    response = NULL;
    
    // Create our request.  Note that NSDictionary is toll-free bridged to CFDictionary, so 
    // we can use an NSDictionary as our request.

	// NSString* path_to_discover_app = @"/Users/neoneye/test.rb";
	NSString* path_to_discover_app = m_path_to_discover_app_executable;
	if(path_to_discover_app == nil) {
		NSLog(@"%s ERROR: path is not initialized", _cmd);
		return;
	}
    
    request = [NSDictionary dictionaryWithObjectsAndKeys:
		@kKCHelperStartListCommand, @kBASCommandKey, 
#if 1
		/*
		TODO: install the Discover.app into /Library/PrivilegedHelperTools
		otherwise we allow users to run arbitrary code as root
		we can't risk that
		*/
		path_to_discover_app, @kKCHelperPathToListProgram,
#endif
		nil];
    assert(request != NULL);
    
    bundleID = [[NSBundle mainBundle] bundleIdentifier];
    assert(bundleID != NULL);
    
    // Execute it.
    
	err = BASExecuteRequestInHelperTool(
        gAuth, 
        kKCHelperCommandSet, 
        (CFStringRef) bundleID, 
        (CFDictionaryRef) request, 
        &response
    );
    
    // If it failed, try to recover.
    
    if ( (err != noErr) && (err != userCanceledErr) ) {
        int alertResult;
        
        failCode = BASDiagnoseFailure(gAuth, (CFStringRef) bundleID);

        // At this point we tell the user that something has gone wrong and that we need 
        // to authorize in order to fix it.  Ideally we'd use failCode to describe the type of 
        // error to the user.
            
        alertResult = NSRunAlertPanel(@"Needs Install", @"BAS needs to install", @"Install", @"Cancel", NULL);
        
        if ( alertResult == NSAlertDefaultReturn ) {
            // Try to fix things.
            
            err = BASFixFailure(gAuth, (CFStringRef) bundleID, CFSTR("InstallKCHelper"), CFSTR("KCHelper"), failCode);

            // If the fix went OK, retry the request.
            
            if (err == noErr) {
                err = BASExecuteRequestInHelperTool(
                    gAuth, 
                    kKCHelperCommandSet, 
                    (CFStringRef) bundleID, 
                    (CFDictionaryRef) request, 
                    &response
                );
            }
        } else {
            err = userCanceledErr;
        }
    }
    
    // If all of the above went OK, it means that the IPC to the helper tool worked.  We 
    // now have to check the response dictionary to see if the command's execution within 
    // the helper tool was successful.
    
    if (err == noErr) {
        err = BASGetErrorFromResponse(response);
    }
    
    // Log our results.
    
    if (err == noErr) {
		NSLog(@"%s OK", _cmd);
    } else {
		NSLog(@"%s Failed with error %ld.", _cmd, (long) err);
    }
    
    if (response != NULL) {
        CFRelease(response);
    }
}

-(void)awakeFromNib {
    // create the toolbar object
    NSToolbar* toolbar = [[[NSToolbar alloc] initWithIdentifier:@"MainWindowToolbar"] autorelease];
 
    // set initial toolbar properties
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
 
    // set our controller as the toolbar delegate
    [toolbar setDelegate:self];
 
    // attach the toolbar to our window
    [m_window setToolbar:toolbar];
}

-(NSArray*)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
    return [NSArray arrayWithObjects:
		opcoders_filter_left_panel_toolbar_item_identifier,
		opcoders_filter_right_panel_toolbar_item_identifier,	
		opcoders_help_toolbar_item_identifier,
		opcoders_menu_toolbar_item_identifier,
		opcoders_view_toolbar_item_identifier,
		opcoders_edit_toolbar_item_identifier,
		opcoders_copy_toolbar_item_identifier,
		opcoders_move_toolbar_item_identifier,
		opcoders_mkdir_toolbar_item_identifier,
		opcoders_delete_toolbar_item_identifier,
        NSToolbarFlexibleSpaceItemIdentifier, 
        NSToolbarSpaceItemIdentifier, 
        NSToolbarSeparatorItemIdentifier, 
		nil
	];
}

-(NSArray*)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar {
    return [NSArray arrayWithObjects:
		opcoders_filter_left_panel_toolbar_item_identifier,
        NSToolbarFlexibleSpaceItemIdentifier, 
		opcoders_help_toolbar_item_identifier,
		opcoders_menu_toolbar_item_identifier,
		opcoders_view_toolbar_item_identifier,
		opcoders_edit_toolbar_item_identifier,
		opcoders_copy_toolbar_item_identifier,
		opcoders_move_toolbar_item_identifier,
		opcoders_mkdir_toolbar_item_identifier,
		opcoders_delete_toolbar_item_identifier,
        NSToolbarFlexibleSpaceItemIdentifier, 
		opcoders_filter_right_panel_toolbar_item_identifier,	
		nil
	];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
     itemForItemIdentifier:(NSString *)ident
 willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem* item = nil;
 
    if([ident isEqualTo:opcoders_filter_left_panel_toolbar_item_identifier]) {
        item = [[[NSToolbarItem alloc] initWithItemIdentifier:ident] autorelease];
        // [item setLabel:@"Filter"];
        [item setPaletteLabel:[item label]];
        [item setToolTip:@"Type in text and the panel will update itself"];
		NSRect r = [m_left_toolbar_searchfield frame];
        [item setView:m_left_toolbar_searchfield];
        [item setMinSize:r.size];
        [item setMaxSize:r.size];
        [item setTarget:self];
        [item setAction:@selector(filterAction:)];
    } else
    if([ident isEqualTo:opcoders_filter_right_panel_toolbar_item_identifier]) {
        item = [[[NSToolbarItem alloc] initWithItemIdentifier:ident] autorelease];
        // [item setLabel:@"Filter"];
        [item setPaletteLabel:[item label]];
        [item setToolTip:@"Type in text and the panel will update itself"];
		NSRect r = [m_right_toolbar_searchfield frame];
        [item setView:m_right_toolbar_searchfield];
        [item setMinSize:r.size];
        [item setMaxSize:r.size];
        [item setTarget:self];
        [item setAction:@selector(filterAction:)];
    } else
    if([ident isEqualTo:opcoders_help_toolbar_item_identifier]) {
        item = [[[NSToolbarItem alloc] initWithItemIdentifier:ident] autorelease];
        [item setLabel:@"1 Help"];
        [item setPaletteLabel:[item label]];
        [item setToolTip:@"Context sensitive help"];
        [item setImage:[NSImage imageNamed:@"keynote_help"]];
        [item setTarget:self];
        [item setAction:@selector(helpAction:)];
    } else
    if([ident isEqualTo:opcoders_menu_toolbar_item_identifier]) {
        item = [[[NSToolbarItem alloc] initWithItemIdentifier:ident] autorelease];
        [item setLabel:@"2 Menu"];
        [item setPaletteLabel:[item label]];
        [item setToolTip:@"User menu"];
		NSRect r = [m_toolbar_popupbutton frame];
        [item setView:m_toolbar_popupbutton];
        [item setMinSize:r.size];
        [item setMaxSize:r.size];
        // [item setImage:[NSImage imageNamed:@"interfacebuilder_gear"]];
        [item setTarget:self];
        [item setAction:@selector(menuAction:)];
    } else
    if([ident isEqualTo:opcoders_view_toolbar_item_identifier]) {
        item = [[[NSToolbarItem alloc] initWithItemIdentifier:ident] autorelease];
        [item setLabel:@"3 View"];
        [item setPaletteLabel:[item label]];
        [item setToolTip:@"View the content of the file"];
        // [item setImage:[NSImage imageNamed:@"finder_quicklook"]];
        [item setImage:[NSImage imageNamed:@"joseph_wain_eye"]];
        [item setTarget:self];
        [item setAction:@selector(viewAction:)];
		m_toolbar_item1 = [item retain];
    } else
    if([ident isEqualTo:opcoders_edit_toolbar_item_identifier]) {
        item = [[[NSToolbarItem alloc] initWithItemIdentifier:ident] autorelease];
        [item setLabel:@"4 Edit"];
        [item setPaletteLabel:[item label]];
        [item setToolTip:@"Edit the content of the file"];
        [item setImage:[NSImage imageNamed:@"iphoto_edit"]];
        [item setTarget:self];
        [item setAction:@selector(editAction:)];
    } else
    if([ident isEqualTo:opcoders_copy_toolbar_item_identifier]) {
        item = [[[NSToolbarItem alloc] initWithItemIdentifier:ident] autorelease];
        [item setLabel:@"5 Copy"];
        [item setPaletteLabel:[item label]];
        [item setToolTip:@"Copy the file(s)"];
        // [item setImage:[NSImage imageNamed:@"copy.png"]];  
        [item setImage:[NSImage imageNamed:@"simon_copy.png"]];
        [item setTarget:self];
        [item setAction:@selector(copyAction:)];
    } else
    if([ident isEqualTo:opcoders_move_toolbar_item_identifier]) {
        item = [[[NSToolbarItem alloc] initWithItemIdentifier:ident] autorelease];
        [item setLabel:@"6 Move"];
        [item setPaletteLabel:[item label]];
        [item setToolTip:@"Move the file(s)"];
        // [item setImage:[NSImage imageNamed:@"move.png"]];
        [item setImage:[NSImage imageNamed:@"simon_move.png"]];
        [item setTarget:self];
        [item setAction:@selector(moveAction:)];
    } else
    if([ident isEqualTo:opcoders_mkdir_toolbar_item_identifier]) {
        item = [[[NSToolbarItem alloc] initWithItemIdentifier:ident] autorelease];
        [item setLabel:@"7 MkDir"];
        [item setPaletteLabel:[item label]];
        [item setToolTip:@"Create a new folder"];
        // [item setImage:[NSImage imageNamed:@"bluetoothfileexchange_newfolder"]];
        [item setImage:[NSImage imageNamed:@"apple_genericfoldericon_with_newfolderbadge"]];
        [item setTarget:self];
        [item setAction:@selector(mkdirAction:)];
		m_toolbar_item7 = [item retain];
    } else
    if([ident isEqualTo:opcoders_delete_toolbar_item_identifier]) {
        item = [[[NSToolbarItem alloc] initWithItemIdentifier:ident] autorelease];
        [item setLabel:@"8 Delete"];
        [item setPaletteLabel:[item label]];
        [item setToolTip:@"Move the file(s) to the trash"];
        [item setImage:[NSImage imageNamed:@"system_delete"]];
        [item setTarget:self];
        [item setAction:@selector(deleteAction:)];
    } else
    {
        item = [[[NSToolbarItem alloc] initWithItemIdentifier:ident] autorelease];
        [item setLabel:@"Unnamed"];
        [item setPaletteLabel:[item label]];
        [item setToolTip:@"Lorem ipsum"];
        [item setImage:[NSImage imageNamed:@"noname.png"]];
        [item setTarget:self];
        // [item setAction:@selector(nonameAction:)];
    }
 
    return item;
}

- (void)applicationWillFinishLaunching:(NSNotification*)notification {
	
	if(g_install_mode) {
		[self installCommandlineToolAction:nil];

	    NSString* bundleID = [[NSBundle mainBundle] bundleIdentifier];
	    assert(bundleID != NULL);
		
	    BASFailCode failCode;
		OSStatus err = BASFixFailure(gAuth, (CFStringRef) bundleID, CFSTR("InstallKCHelper"), CFSTR("KCHelper"), failCode);

        // If the fix went OK, retry the request.
        
        if (err == noErr) {
			NSLog(@"%s installed ok", _cmd);
		} else {
			NSLog(@"%s ERROR: couldn't install KCHelper", _cmd);
		}
        
		
		exit(0);
		return;
	}

	[DirCache shared];
	
	[self locateDiscoverAppExecutable];
	[self locateReportAppExecutable];
	[self locateCopyAppExecutable];
	[[KCCopySheet shared] setExecPath:m_path_to_copy_app_executable];
	

	[self maybeShowDiscoverStatWindow];
	[self maybeShowReportStatWindow];
	
	{
		[m_left_pane setTableView:m_left_tableview];
		[m_right_pane setTableView:m_right_tableview];
		[m_left_pane setTextView:m_left_textview];
		[m_right_pane setTextView:m_right_textview];
		[m_left_pane setPathComboBox:m_left_path_combobox];
		[m_right_pane setPathComboBox:m_right_path_combobox];
		[m_left_pane setQuickLookButton:m_left_quicklook_button];
		[m_right_pane setQuickLookButton:m_right_quicklook_button];
		[m_left_pane setTabView:m_left_tabview];
		[m_right_pane setTabView:m_right_tabview];
		[m_left_pane setSearchField:m_left_toolbar_searchfield];
		[m_right_pane setSearchField:m_right_toolbar_searchfield];
		[m_left_pane setDiscoverStatItems:m_discover_stat_items];
		[m_right_pane setDiscoverStatItems:m_discover_stat_items];
	}

	{
		[m_left_pane installCustomCells];
		[m_right_pane installCustomCells];
	}

	{
		[m_left_tableview setDelegate:m_left_pane];
		[m_right_tableview setDelegate:m_right_pane];
		[m_left_tableview setDataSource:m_left_pane];
		[m_right_tableview setDataSource:m_right_pane];
		[m_left_toolbar_searchfield setDelegate:m_left_pane];
		[m_right_toolbar_searchfield setDelegate:m_right_pane];
		[m_left_report_textview setDelegate:self];
		[m_right_report_textview setDelegate:self];
	}

	[self syncFontSettings];
	
	{
		NSColor* color = [NSColor colorWithCalibratedWhite:0.8 alpha:1.0];
		[m_left_tableview setBackgroundColor:color];
		[m_right_tableview setBackgroundColor:color];
	}
	{
		// NSColor* color = [NSColor colorWithCalibratedWhite:0.97 alpha:1.0];
		NSColor* color = [NSColor whiteColor];
		[m_left_textview setBackgroundColor:color];
		[m_right_textview setBackgroundColor:color];
	}


	[self reloadLeft];
	[self reloadRight];
	[self reloadWindowTitle];
	[self reloadPathControls];
	
	{
		NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:0];
		[m_left_tableview selectRowIndexes:indexes byExtendingSelection:NO];
		[m_right_tableview selectRowIndexes:indexes byExtendingSelection:NO];
	}

	{
		NSString* home = NSHomeDirectory();
		NSArray* path = [home stringByAppendingPathComponent:@"Desktop"];

		[m_left_pane changePath:path];
		[m_right_pane changePath:path];
		// [m_left_pane gotoBookmarkIndex:1];
		// [m_right_pane gotoBookmarkIndex:1];
		// [m_left_pane changePath:@"/usr/share/man/man3"]; // 6225 objects
		// [m_left_pane changePath:@"/usr/bin"];
		// [m_left_pane changePath:@"/Volumes/Data/modules"];
		// [m_left_pane changePath:@"/Volumes/Data/movies1"];
		// [m_right_pane changePath:@"/Users/neoneye/Desktop/crap"];
		[self reloadPathControls];
	}

	{
		NSAssert(m_left_discover == nil, @"must not be initialized");
		m_left_discover = [[KCDiscover alloc] initWithName:@"left" path:m_path_to_discover_app_executable auth:gAuth];
		[m_left_discover setDelegate:m_left_pane];
		[m_left_pane setWrapper:m_left_discover];
		[m_left_discover start];
	}
	{
		NSAssert(m_right_discover == nil, @"must not be initialized");
		m_right_discover = [[KCDiscover alloc] initWithName:@"right" path:m_path_to_discover_app_executable auth:gAuth];
		[m_right_discover setDelegate:m_right_pane];
		[m_right_pane setWrapper:m_right_discover];
		[m_right_discover start];
	}
	
	{
		[m_left_pane registerForDraggedTypes];
		[m_right_pane registerForDraggedTypes];
	}
	
	if(0) {
		NSView* view = m_left_tableview;
		NSImage* img = [NSImage imageNamed:@"info_emptydir"];
		NSSize s = [img size];
		NSRect f = [view frame];
		NSRect r = NSMakeRect(
			floorf((NSWidth(f) - s.width) * 0.5),
			floorf((NSHeight(f) - s.height) * 0.5),
			s.width, 
			s.height
		);
		NSButton* b = [[NSButton alloc] initWithFrame:r];
		[b setTitle:@"test"];
		[b setImage:img];
		[b setBordered:NO];
		[view addSubview:b];
		[b release];
	}

	if(0) {
		NSView* view = m_right_tableview;
		NSImage* img = [NSImage imageNamed:@"info_fsbusy"];
		NSSize s = [img size];
		NSRect f = [view frame];
		NSRect r = NSMakeRect(
			floorf((NSWidth(f) - s.width) * 0.5),
			floorf((NSHeight(f) - s.height) * 0.5),
			s.width, 
			s.height
		);
		NSButton* b = [[NSButton alloc] initWithFrame:r];
		[b setTitle:@"test"];
		[b setImage:img];
		[b setBordered:NO];
		[view addSubview:b];
		[b release];
	}

	[m_window makeKeyAndOrderFront:self];
}

- (void)applicationDidFinishLaunching:(NSNotification*)notification {
	if(g_install_mode) {
		return;
	}

	[m_left_pane activate];

	/*
	takes about 0.4 seconds on my macmini 1.8 GHz to start the program.
	loading just a MainMenu.nib takes 0.08 seconds so there is a long
	way to go before the program starts up in a good speed.
	*/
	// float seconds = seconds_since_program_start();
	// NSLog(@"App start took %.3f seconds", seconds);


	
	[self performSelector: @selector(initEverything)
	           withObject: nil
	           afterDelay: 0.0];
}

-(void)runTest1 {
	NSLog(@"%s", _cmd);
	
	AuthorizationRef myAuthorizationRef;
	OSStatus myStatus;
	myStatus = AuthorizationCreate (NULL, kAuthorizationEmptyEnvironment,
	            kAuthorizationFlagDefaults, &myAuthorizationRef);	


	AuthorizationItem myItems[1];

	myItems[0].name = kAuthorizationRightExecute;
	// myItems[0].name = "com.opcoders.OrthodoxFileManager.read";
	myItems[0].valueLength = 0;
	myItems[0].value = NULL;
	myItems[0].flags = 0;


	AuthorizationRights myRights;
	myRights.count = sizeof (myItems) / sizeof (myItems[0]);
	myRights.items = myItems;


	AuthorizationFlags myFlags;
	myFlags = kAuthorizationFlagDefaults |
	            kAuthorizationFlagInteractionAllowed |
	            kAuthorizationFlagExtendRights;

	myStatus = AuthorizationCopyRights (myAuthorizationRef, &myRights,
		kAuthorizationEmptyEnvironment, myFlags, NULL);



    if(myStatus != errAuthorizationSuccess) {
		NSLog(@"%s ERROR: failed to authorize", _cmd);
		myStatus = AuthorizationFree (myAuthorizationRef,
		            kAuthorizationFlagDestroyRights);
		return;
	}

	NSLog(@"%s good", _cmd);
	
	// system("ls /Users/johndoe/Desktop");
	// system("whoami");

#if 0
	NSFileManager* fm = [NSFileManager defaultManager];

	NSString* path = @"/Users/johndoe/Desktop";
	NSError* error = nil;

	NSArray* filenames = [fm contentsOfDirectoryAtPath:path error:&error];

	NSLog(@"%s filenames: %@", _cmd, filenames);
#endif

	
	char* argv[2] = { "/Users/johndoe/Desktop", NULL };
  	// char* argv[2] = { "/Users/johndoe", NULL };
  // char* argv[2] = { "/Users", NULL };
	// char* argv[2] = { "/Users/neoneye/Desktop", NULL };

#if 0
    FTS* fts;
    FTSENT* dirlist;
    FTSENT* fileinfo;
    fts = fts_open(argv, FTS_COMFOLLOW, NULL);
	dirlist = fts_children(fts, FTS_NAMEONLY);
	do
	{
/*		 fileinfo = fts_read(dirlist->fts_pointer);
		if(fileinfo) {
			NSLog(@"%s %s", _cmd, fileinfo->fts_name);
		}

		 fileStruct = fts_open(dirlist->fts_link->fts_name, 
		FTS_PHYSICAL, (void *)result); */

	}while (dirlist->fts_link != NULL);
    fts_close(fts);
#endif
#if 1
    FTSENT* p;
    FTS* fts = fts_open(argv, FTS_COMFOLLOW, NULL);
    while((p = fts_read(fts)) != NULL) {
		// NSLog(@"%s: name: %s", _cmd, p->fts_name);
        switch(p->fts_info) {
        case FTS_F:
			NSLog(@"file: %s", p->fts_name);
			break;
        case FTS_D:
			NSLog(@"dir: %s", p->fts_name);
			if(p->fts_level > 0) {
				fts_set(fts, p, FTS_SKIP);
			}
            break;
        }
    }
    fts_close(fts);
#endif

	myStatus = AuthorizationFree (myAuthorizationRef,
	            kAuthorizationFlagDestroyRights);
}

-(void)runTest2 {
	NSLog(@"%s", _cmd);
	
#if 0	
	if(0) {
		NSFileManager* fm = [NSFileManager defaultManager];
		NSString* path = @"/";
		NSError* error = nil;
		NSArray* filenames = [fm contentsOfDirectoryAtPath:path error:&error];
		NSLog(@"%s filenames: %@", _cmd, filenames);
	}

	
	if(0) {
		char* argv[2] = { "/", NULL };
	#if 0
	    FTS* fts;
	    FTSENT* dirlist;
	    FTSENT* fileinfo;
	    fts = fts_open(argv, FTS_COMFOLLOW, NULL);
		dirlist = fts_children(fts, FTS_NAMEONLY);
		do
		{
/*			 fileinfo = fts_read(dirlist->fts_pointer);
			if(fileinfo) {
				NSLog(@"%s %s", _cmd, fileinfo->fts_name);
			}

			 fileStruct = fts_open(dirlist->fts_link->fts_name, 
			FTS_PHYSICAL, (void *)result); */

		}while (dirlist->fts_link != NULL);
	    fts_close(fts);
	#endif
	#if 1
	    FTSENT* p;
	    FTS* fts = fts_open(argv, FTS_COMFOLLOW, NULL);
	    while((p = fts_read(fts)) != NULL) {
			// NSLog(@"%s: name: %s", _cmd, p->fts_name);
	        switch(p->fts_info) {
	        case FTS_F:
				NSLog(@"file: %s", p->fts_name);
				break;
	        case FTS_D:
				NSLog(@"dir: %s", p->fts_name);
				if(p->fts_level > 0) {
					fts_set(fts, p, FTS_SKIP);
				}
	            break;
	        }
	    }
	    fts_close(fts);
	#endif
	}

	if(0) {
		DIR* dirp;
		struct dirent* dp;
		dirp = opendir("/");
		while((dp = readdir(dirp)) != NULL) {
			NSLog(@"%s Xfilename: %s", _cmd, dp->d_name);
		}
		closedir(dirp);
   	}

	{
		NSLog(@"%s before print", _cmd);
		PrintGetDirEntriesInfo("/", 0, 0);
		NSLog(@"%s after print", _cmd);
	}

	{
		NSLog(@"%s before print", _cmd);
		// PrintGetDirEntriesInfo("/usr/share/man/man3", 0, 0);
		// PrintGetDirEntriesInfo("/net", 0, 0);
		// PrintGetDirEntriesInfo("/Volumes/Test1", 0, 0);
		PrintGetDirEntriesInfo("/usr/local/lib", 0, 0);
		NSLog(@"%s after print", _cmd);
	}
#endif
	
	{
		NSLog(@"%s before print", _cmd);
		MyGetDirEntries cde;
		cde.run("/");
		NSArray* ary = cde.get_filenames();
		NSLog(@"%s %@", _cmd, ary);
		// cde.run("/Users/johndoe/Desktop");
		NSLog(@"%s after print", _cmd);
	}

}

-(void)runTest3 {
	NSLog(@"%s BEFORE", _cmd);
	PanelTable* pt = [[[PanelTable alloc] init] autorelease];
	[pt test];
	NSLog(@"%s AFTER", _cmd);
	exit(0);
}

-(void)runTest4 {
	NSLog(@"%s BEFORE", _cmd);

	NSMutableIndexSet* iset = [[NSMutableIndexSet alloc] init];
	NSAssert([iset count] == 0, @"count must be zero");
	[iset addIndex:5];
	NSAssert([iset count] == 1, @"count must be 1");
	[iset addIndex:6];
	NSAssert([iset count] == 2, @"count must be 2");
	[iset addIndex:10];
	NSAssert([iset count] == 3, @"count must be 3");
	NSLog(@"%s AFTER", _cmd);
	exit(0);
}

-(void)initEverything {
	[[JFActionMenu shared] setDelegate:self];
	[[JFActionMenu shared] menu]; // rebuild the menu, so it's ready

	[[JFBookmarkMenu shared] setDelegate:self];
	[[JFBookmarkMenu shared] rebuildMenu]; // rebuild the menu, so it's ready
	
	/*
	register help book
	*/
	OSStatus err = register_my_help_book();
	if(err == noErr) {
		// NSLog(@"%s help book registered successfully", _cmd);
	} else {
		NSLog(@"%s ERROR: failed registering help book", _cmd);
	}
	
	// [self showPreferencesPanel:self];
	// [self showBookmarkPreferencesPanel:self];

	// [self runTest1];
	// [self runTest2];
	// [self runTest3];                          
	// [self runTest4];
	// [self doGetVersion:self];
	// [self doLaunchDiscover:self];
	return;
/*	{
		NSLog(@"%s 1", _cmd);
		[[KCCopySheet shared] showAskSheet:m_window];
		NSLog(@"%s 2", _cmd);
		[[KCCopySheet shared] showPerformSheet:m_window];
		NSLog(@"%s 3", _cmd);
	} /**/
}

-(OFMPane*)activePane {
	if([m_window firstResponder] == m_left_tableview) {
		return m_left_pane;
	}
	if([m_window firstResponder] == m_right_tableview) {
		return m_right_pane;
	}
	return nil;
}

-(OFMPane*)inactivePane {
	if([m_window firstResponder] == m_left_tableview) {
		return m_right_pane;
	}
	if([m_window firstResponder] == m_right_tableview) {
		return m_left_pane;
	}
	return nil;
}

-(void)reloadLeft {
	[m_left_pane update];
	[m_left_pane refreshUI];
}

-(void)reloadRight {
	[m_right_pane update];
	[m_right_pane refreshUI];
}

-(void)reloadPathControls {
	[m_left_pane refreshPathControl];
	[m_right_pane refreshPathControl];
}

-(void)syncFontSettings {
	{
		NSFont* font = [NSFont systemFontOfSize: 12];
		font = [[NSFontManager sharedFontManager] convertFont:font 
			toHaveTrait:NSBoldFontMask];
			
		[m_left_pane setTextViewFont:font];
		[m_right_pane setTextViewFont:font];
	}

	{
		NSString* fontname1 = @"BitstreamVeraSansMono-Roman";
		NSString* fontname2 = @"Monaco";
		float fontsize = m_table_font_size;
		NSFont* font = [NSFont fontWithName:fontname1 size:fontsize];
		if(font == nil) {
			font = [NSFont fontWithName:fontname2 size:fontsize];
		}
#if 1
		font = nil; // force non-monospaced font
#endif
		if(font == nil) {
			font = [NSFont systemFontOfSize: fontsize];
		}
		int row_height = [font defaultLineHeightForFont];
#if 0
		row_height += 6; // seems best with monospaced fonts
#endif
#if 1
		row_height += 4; // seems best with propertional fonts
#endif
		
		NSSize spacing = NSZeroSize;
		[m_left_tableview setIntercellSpacing:spacing];
		[m_right_tableview setIntercellSpacing:spacing];

	    [m_left_tableview setRowHeight:row_height];
	    [m_left_tableview setFont:font];		
		[m_left_pane setTableViewFont:font];
		[m_left_pane reloadTableAttributes];

	    [m_right_tableview setRowHeight:row_height];
	    [m_right_tableview setFont:font];		
		[m_right_pane setTableViewFont:font];
		[m_right_pane reloadTableAttributes];
	}
	
}

-(void)readonlyTableviewTabAway:(NSNotification*)aNotification {
	// NSLog(@"%s", _cmd);
	id thing = [aNotification object];
	if(thing == m_left_report_textview) {
		[m_right_pane activate];
	}
	if(thing == m_right_report_textview) {
		[m_left_pane activate];
	}
}

-(void)tabAwayFromPane:(OFMPane*)pane {
	// NSLog(@"AppDelegate %s", _cmd);
	if(pane == m_left_pane) {

		NSTabView* tv = m_right_tabview;
		int index = [tv indexOfTabViewItem:[tv selectedTabViewItem]];
		if(index == 0) {
			[m_right_pane activate];
		} else
		if(index == 1) {
			// do nothing
		} else
		if(index == 2) {
			[m_window makeFirstResponder:m_right_report_textview];
		}

	} else
	if(pane == m_right_pane) {
		
		NSTabView* tv = m_left_tabview;
		int index = [tv indexOfTabViewItem:[tv selectedTabViewItem]];
		if(index == 0) {
			[m_left_pane activate];
		} else
		if(index == 1) {
			// do nothing
		} else
		if(index == 2) {
			[m_window makeFirstResponder:m_left_report_textview];
		}
	}
}

-(void)reloadQuickLook {
	NSString* path = nil;   
	NSButton* quicklook_button = nil;
	NSTabView* tv = nil;

	NSWindow* win = m_window;
	if([win firstResponder] == m_left_tableview) {
		path = [m_left_pane pathForCurrentRow];
		quicklook_button = m_right_quicklook_button;
		tv = m_right_tabview;
	}
	if([win firstResponder] == m_right_tableview) {
		path = [m_right_pane pathForCurrentRow];
		quicklook_button = m_left_quicklook_button;
		tv = m_left_tabview;
	}
	
	if(path == nil) {
		return;
	}
	if(quicklook_button == nil) {
		return;
	}
	int index = [tv indexOfTabViewItem:[tv selectedTabViewItem]];
	if(index != 1) {
		return;
	}

	NSSize size = [quicklook_button frame].size;
	float v = MIN(size.width, size.height);
	size.width = v;
	size.height = v;
	NSImage* img = [NSImage imageWithPreviewOfFileAtPath:path ofSize:size asIcon:YES];
	[quicklook_button setImage:img];
}





-(void)selectionDidChange:(OFMPane*)pane {
	// NSLog(@"%s", _cmd);
	[self reloadQuickLook];
	[self reloadReport];
}

-(void)reloadWindowTitle {
#if 0
	if([m_window firstResponder] == m_left_tableview) {
		[m_window setTitle:[m_left_pane windowTitle]]; 
	}
	if([m_window firstResponder] == m_right_tableview) {
		[m_window setTitle:[m_right_pane windowTitle]]; 
	}
#else
	// [m_window setTitle:@"FTP - Read Only - Newton Commander"]; 
	[m_window setTitle:@"Newton Commander"]; 
#endif
}

-(void)mainWindow:(JFMainWindow*)mainWindow
     flagsChanged:(NSUInteger)flags 
{
	BOOL is_cmd = ((flags & NSCommandKeyMask) != 0);
	BOOL is_alt = ((flags & NSAlternateKeyMask) != 0);
	BOOL is_ctrl = ((flags & NSControlKeyMask) != 0);
	BOOL is_shft = ((flags & NSShiftKeyMask) != 0);
		
	// NSLog(@"%s cmd: %i  alt: %i  ctrl: %i  shift: %i  (flags: %08x)", _cmd, is_cmd, is_alt, is_ctrl, is_shft, flags); /**/
	
	if(is_cmd) {
	    [m_toolbar_item1 setImage:[NSImage imageNamed:@"system_info"]];
        [m_toolbar_item1 setLabel:@"3 Info"];

	    [m_toolbar_item7 setImage:[NSImage imageNamed:@"apple_genericdocumenticon_with_newfolderbadge"]];
        [m_toolbar_item7 setLabel:@"7 MkFile"];
	} else {
	    // [m_toolbar_item1 setImage:[NSImage imageNamed:@"finder_quicklook"]];
	    [m_toolbar_item1 setImage:[NSImage imageNamed:@"joseph_wain_eye"]];
        [m_toolbar_item1 setLabel:@"3 View"];

        [m_toolbar_item7 setImage:[NSImage imageNamed:@"apple_genericfoldericon_with_newfolderbadge"]];
        [m_toolbar_item7 setLabel:@"7 MkDir"];
	}

	/*
	F7 = mkdir
	CMD F7 = mkfile
	
	*/

}


-(IBAction)swapTabs:(id)sender {

	NSString* path1 = [m_left_pane path];
	NSString* path2 = [m_right_pane path];

	int row1 = [m_left_tableview selectedRow];
	int row2 = [m_right_tableview selectedRow];

	NSRect rect1 = [[m_left_tableview enclosingScrollView] documentVisibleRect];
	NSRect rect2 = [[m_right_tableview enclosingScrollView] documentVisibleRect];

	[m_left_pane changePath:path2];
	[m_right_pane changePath:path1];
	[self reloadLeft];
	[self reloadRight];
	
	[m_left_pane setRow:row2];
	[m_right_pane setRow:row1];

	[self reloadLeft];
	[self reloadRight];

	{
		NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:row2];
		[m_left_tableview selectRowIndexes:indexes byExtendingSelection:NO];
	}
	{
		NSIndexSet* indexes = [NSIndexSet indexSetWithIndex:row1];
		[m_right_tableview selectRowIndexes:indexes byExtendingSelection:NO];
	}


	[m_left_tableview scrollRowToVisible:row2];
	[m_right_tableview scrollRowToVisible:row1];
	[m_left_tableview scrollRectToVisible:rect2];
	[m_right_tableview scrollRectToVisible:rect1];
	
	[m_left_pane swapBreadcrums:m_right_pane];
	

	NSWindow* win = m_window;
	if([win firstResponder] == m_left_tableview) {
		[m_window makeFirstResponder:m_right_tableview];
	} else
	if([win firstResponder] == m_right_tableview) {
		[m_window makeFirstResponder:m_left_tableview];
	}
}

-(IBAction)mirrorTabs:(id)sender {
	NSWindow* win = m_window;
	if([win firstResponder] == m_left_tableview) {
		[m_right_pane changePath:[m_left_pane path]];
		[self reloadRight];
		[m_right_pane takeBreadcrumsFrom:m_left_pane];
	}
	if([win firstResponder] == m_right_tableview) {
		[m_left_pane changePath:[m_right_pane path]];
		[self reloadLeft];
		[m_left_pane takeBreadcrumsFrom:m_right_pane];
	}
}

-(IBAction)cycleInfoPanes:(id)sender {
	[[self activePane] cycleActiveInfoPanel];
}

-(void)jumpToBookmarkPath:(NSString*)path {
	// NSLog(@"%s TODO fill me in. path: %@", _cmd, path);

	NSWindow* win = m_window;
	if([win firstResponder] == m_left_tableview) {
		[m_left_pane eraseBreadcrums];
		[m_left_pane changePath:path];
		[self reloadLeft];
		[m_left_pane rebuildInfo];
		[self reloadLeft];
	}
	if([win firstResponder] == m_right_tableview) {
		[m_right_pane eraseBreadcrums];
		[m_right_pane changePath:path];
		[self reloadRight];
		[m_right_pane rebuildInfo];
		[self reloadRight];
	}
	[self reloadWindowTitle];
	[self reloadPathControls];

}

-(IBAction)revealInFinder:(id)sender {
	[[self activePane] revealInFinder];
}

-(IBAction)revealInfoInFinder:(id)sender {
	NSString* path = [[self activePane] pathForCurrentRow];
	if(path == nil) return;

	NSFileManager* fm = [NSFileManager defaultManager];
	BOOL isdir = NO;
	BOOL ok = [fm fileExistsAtPath:path isDirectory:&isdir];
	if(!ok) return;

	NSString* script_folder = @""
	"on run argv\n"
	"  set absolute_path to item 1 of argv\n"
	"  set absolute_path2 to POSIX file absolute_path as text\n"
	"  tell application \"Finder\"\n"
	"  activate\n"
	"    open information window of folder absolute_path2\n"
	"  end tell\n"
	"end run\n";

	NSString* script_file = @""
	"on run argv\n"
	"  set absolute_path to item 1 of argv\n"
	"  set absolute_path2 to POSIX file absolute_path as text\n"
	"  tell application \"Finder\"\n"
	"  activate\n"
	"    open information window of file absolute_path2\n"
	"  end tell\n"
	"end run\n";

	NSString* script = isdir ? script_folder : script_file;
	NSArray* args = [NSArray arrayWithObjects:@"-", path, nil];
	[self runAppleScript:script arguments:args];
}

-(IBAction)selectCenterRow:(id)sender {
	[[self activePane] selectCenterRow];
}

-(IBAction)renameAction:(id)sender {
	[[self activePane] editFilename];
}

-(int)mkTransactionId {
	int tid = m_transaction_id_seed;
	m_transaction_id_seed = (tid + 1) & 0xffff;
	return tid;
}

-(void)pane:(OFMPane*)pane renameFromPath:(NSString*)fromPath toPath:(NSString*)toPath {
	// NSLog(@"%s", _cmd);
	[self renameFromPath:fromPath toPath:toPath];

	[self reloadLeft];
	[self reloadRight];
	[m_left_pane rebuildInfo];
	[m_right_pane rebuildInfo];
	[self reloadLeft];
	[self reloadRight];
	[self reloadWindowTitle];
}

-(void)renameFromPath:(NSString*)src_path toPath:(NSString*)dest_path {
	// NSLog(@"%s\nrename from:\n%@\n\nrename to:\n%@\n\n", _cmd, src_path, dest_path);

	// only allow rename inside the same dir
	NSString* base_path1 = [src_path stringByDeletingLastPathComponent];
	NSString* base_path2 = [dest_path stringByDeletingLastPathComponent];
	if([base_path1 isEqualToString:base_path2] == NO) {
		NSLog(@"ERROR: cannot rename. Base paths must be the same\n%@\n%@", base_path1, base_path2);
		return;
	}

	// make sure the filenames are good
	NSString* lp1 = [src_path lastPathComponent];
	NSString* lp2 = [dest_path lastPathComponent];
	if(([lp1 length] == 0) || ([lp2 length] == 0)) {
		NSLog(@"ERROR: cannot rename. Filenames must not be empty");
		return;
	}
	
	NSError* error = nil;
	NSFileManager* fm = [NSFileManager defaultManager];

	/*
	HACK: [NSFileManager moveItemAtPath] won't allow us to
	rename from "test" to "TEST". Internally moveItemAtPath
	must do a case-in-sensitive match and refuse to do the
	renaming if the strings are equal.
	
	SOLUTION: rename to a temporary name.
	*/
	lp1 = [lp1 lowercaseString];
	lp2 = [lp2 lowercaseString];
	if([lp1 isEqualToString:lp2]) {
		// NSLog(@"%s SAME, need temporary rename", _cmd);

		NSString* tmpname = [lp1 stringByAppendingPathExtension:@"tempname"];
		NSString* tmp_path = [base_path1 stringByAppendingPathComponent:tmpname];

		BOOL ok = [fm moveItemAtPath:src_path toPath:tmp_path error:&error];
		if(!ok) {
			NSLog(@"ERROR: couldn't rename temporary file\n%@", error);
			return;
		} else {
			NSLog(@"renamed to temporary file");
		}
		
		src_path = tmp_path;
	}

	{
		BOOL ok = [fm moveItemAtPath:src_path toPath:dest_path error:&error];
		if(!ok) {
			NSLog(@"%s ERROR: couldn't rename file\n%@", _cmd, error);
			return;
		}
	}
	NSLog(@"File renamed successfully\nFrom: \"%@\"\nTo: \"%@\"", src_path, dest_path);
}

-(IBAction)mkdirAction:(id)sender {
	NSString* path = nil;

	NSWindow* win = m_window;
	if([win firstResponder] == m_left_tableview) {
		path = [m_left_pane pathForCurrentRow];
	}
	if([win firstResponder] == m_right_tableview) {
		path = [m_right_pane pathForCurrentRow];
	}
	
	[m_mkdir_location autorelease];
	m_mkdir_location = [[path stringByDeletingLastPathComponent] retain];
	
	NSString* suggested_name = (path != nil) ? [path lastPathComponent] : @"New folder";

	
	[m_alert autorelease];
	m_alert = nil;

	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"OK"];
	[alert addButtonWithTitle:@"Cancel"];
	[alert setMessageText:@"Make dir"];
	[alert setInformativeText:@"Create directory in the current folder."];
	[alert setAlertStyle:NSInformationalAlertStyle];
	
	[m_mkdir_alert_textfield setStringValue:suggested_name];
	[alert setAccessoryView:m_mkdir_alert_accessory];
	
	
	m_alert = alert;
	
	[alert beginSheetModalForWindow:m_window modalDelegate:self didEndSelector:@selector(mkdirAlertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
	[[alert window] makeFirstResponder:m_mkdir_alert_textfield];
}

-(void)mkdirAlertDidEnd:(NSAlert*)alert
            returnCode:(int)rc 
           contextInfo:(void*)ctx
{
	// NSLog(@"%s", _cmd);
	do {
		if(rc != NSAlertFirstButtonReturn) {
			NSLog(@"mkdir was cancelled by user");
			break;
		}

		// NSLog(@"%s ok", _cmd);
		
		NSString* dirname = [m_mkdir_alert_textfield stringValue];
		NSString* path = [m_mkdir_location stringByAppendingPathComponent:dirname];
		// NSLog(@"%s %@\n%@", _cmd, dirname, path);

		NSFileManager* fm = [NSFileManager defaultManager];
		
		NSError* error = nil;
		BOOL ok = [fm createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:&error];
		if(ok) {
			NSLog(@"created dir: %@", path);
		} else {
			NSLog(@"ERROR: cannot create dir\n%@\n%@", error, path);
		}
		
	} while(0);
	
	[m_alert autorelease];
	m_alert = nil;
	
	[m_mkdir_location autorelease];
	m_mkdir_location = nil;

	[self reloadLeft];
	[self reloadRight];
	[m_left_pane rebuildInfo];
	[m_right_pane rebuildInfo];
	[self reloadLeft];
	[self reloadRight];
	[self reloadWindowTitle];
}


-(IBAction)mkfileAction:(id)sender {
	NSString* path = nil;

	NSWindow* win = m_window;
	if([win firstResponder] == m_left_tableview) {
		path = [m_left_pane pathForCurrentRow];
	}
	if([win firstResponder] == m_right_tableview) {
		path = [m_right_pane pathForCurrentRow];
	}
	
	if(path == nil) {
		return;
	}
	
	[m_mkfile_location autorelease];
	m_mkfile_location = [[path stringByDeletingLastPathComponent] retain];
	
	NSString* suggested_name = (path != nil) ? [path lastPathComponent] : @"New file";

	
	[m_alert autorelease];
	m_alert = nil;

	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"OK"];
	[alert addButtonWithTitle:@"Cancel"];
	[alert setMessageText:@"Make file"];
	[alert setInformativeText:@"Create file in the current folder."];
	[alert setAlertStyle:NSInformationalAlertStyle];
	
	[m_mkfile_alert_textfield setStringValue:suggested_name];
	[alert setAccessoryView:m_mkfile_alert_accessory];
	
	
	m_alert = alert;
	
	[alert beginSheetModalForWindow:m_window modalDelegate:self didEndSelector:@selector(mkfileAlertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
	[[alert window] makeFirstResponder:m_mkfile_alert_textfield];
}

-(void)mkfileAlertDidEnd:(NSAlert*)alert
            returnCode:(int)rc 
           contextInfo:(void*)ctx
{
	// NSLog(@"%s", _cmd);
	do {
		if(rc != NSAlertFirstButtonReturn) {
			NSLog(@"mkfile was cancelled by user");
			break;
		}

		// NSLog(@"%s ok", _cmd);
		
		NSString* filename = [m_mkfile_alert_textfield stringValue];
		NSString* path = [m_mkfile_location stringByAppendingPathComponent:filename];
		// NSLog(@"%s %@\n%@", _cmd, filename, path);

		NSFileManager* fm = [NSFileManager defaultManager];
		
		NSData* contents = [NSData data];
		NSDictionary* attributes = [NSDictionary dictionary];

		BOOL ok = [fm createFileAtPath:path contents:contents attributes:attributes];
		if(ok) {
			NSLog(@"created file: %@", path);
		} else {
			NSLog(@"ERROR: cannot create file\n%@", path);
		}
		
	} while(0);
	
	[m_alert autorelease];
	m_alert = nil;
	
	[m_mkfile_location autorelease];
	m_mkfile_location = nil;

	[self reloadLeft];
	[self reloadRight];
	[m_left_pane rebuildInfo];
	[m_right_pane rebuildInfo];
	[self reloadLeft];
	[self reloadRight];
	[self reloadWindowTitle];
}

-(IBAction)deleteAction:(id)sender {

	[m_delete_path autorelease];
	m_delete_path = nil;

	[m_alert autorelease];
	m_alert = nil;

	NSString* path = nil;
	NSWindow* win = m_window;
	if([win firstResponder] == m_left_tableview) {
		path = [m_left_pane pathForCurrentRow];
	}
	if([win firstResponder] == m_right_tableview) {
		path = [m_right_pane pathForCurrentRow];
	}
	
	if(path == nil) {
		return;
	}

	m_delete_path = [path retain];

	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"OK"];
	[alert addButtonWithTitle:@"Cancel"];
	[alert setMessageText:@"Delete selected file"];
	[alert setInformativeText:@"Are you sure you want to delete it."];
	[alert setAlertStyle:NSCriticalAlertStyle];
	
	m_alert = alert;
	
	[alert beginSheetModalForWindow:m_window modalDelegate:self didEndSelector:@selector(deleteAlertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

-(void)deleteAlertDidEnd:(NSAlert*)alert
            returnCode:(int)rc 
           contextInfo:(void*)ctx
{
	// NSLog(@"%s", _cmd);
	do {
		if(rc != NSAlertFirstButtonReturn) {
			NSLog(@"delete was cancelled by user");
			break;
		}

		NSLog(@"moving object to trash\n%@", m_delete_path);
		
		if(m_delete_path == nil) {
			break;
		}

		OSStatus status = FSPathMoveObjectToTrashSync(
			[m_delete_path UTF8String],
			NULL,
			kFSFileOperationDefaultOptions
		);
		
		if(status == 0) {
			NSLog(@"moved to trash successfully");
		} else {
			NSLog(@"ERROR: couldn't move to trash. Code=%i", (int)status);
		}
		
	} while(0);
	
	[m_alert autorelease];
	m_alert = nil;

	[m_delete_path autorelease];
	m_delete_path = nil;

	[self reloadLeft];
	[self reloadRight];
	[m_left_pane rebuildInfo];
	[m_right_pane rebuildInfo];
	[self reloadLeft];
	[self reloadRight];
	[self reloadWindowTitle];
}

-(IBAction)moveAction:(id)sender {
	NSTabView* tv = nil;
	NSString* src_path = nil;
	NSString* dst_path = nil;
	NSWindow* win = m_window;
	if([win firstResponder] == m_left_tableview) {
		tv = m_right_tabview;
		src_path = [m_left_pane pathForCurrentRow];
		dst_path = [m_right_pane path];
	}
	if([win firstResponder] == m_right_tableview) {
		tv = m_left_tabview;
		dst_path = [m_left_pane path];
		src_path = [m_right_pane pathForCurrentRow];
	}
	
	if(tv == nil) {
		return;
	}
	if(src_path == nil) {
		return;
	}
	if(dst_path == nil) {
		return;
	}
	// NSLog(@"%s\nfrom: %@\nto: %@", _cmd, src_path, dst_path);

	int index = [tv indexOfTabViewItem:[tv selectedTabViewItem]];
	if(index != 0) {
		return;
	}

	NSString* filename = [src_path lastPathComponent];
	NSString* suggested_path = [dst_path stringByAppendingPathComponent:filename];
    
	[m_move_src_location autorelease];
	m_move_src_location = [src_path retain];
	
	[m_alert autorelease];
	m_alert = nil;

	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"OK"];
	[alert addButtonWithTitle:@"Cancel"];
	[alert setMessageText:@"Move file/dir"];
	[alert setInformativeText:@"What destination dir do you want it moved to."];
	[alert setAlertStyle:NSInformationalAlertStyle];
	
	[m_move_alert_textfield setStringValue:suggested_path];
	[alert setAccessoryView:m_move_alert_accessory];
	
	
	m_alert = alert;
	
	[alert beginSheetModalForWindow:m_window modalDelegate:self didEndSelector:@selector(moveAlertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
	[[alert window] makeFirstResponder:m_move_alert_textfield];
}

-(void)moveAlertDidEnd:(NSAlert*)alert
            returnCode:(int)rc 
           contextInfo:(void*)ctx
{
	// NSLog(@"%s", _cmd);
	do {
		if(rc != NSAlertFirstButtonReturn) {
			NSLog(@"move was cancelled by user");
			break;
		}

		NSLog(@"moving objects");

		NSString* src_path = m_move_src_location;
		
		if(src_path == nil) {
			NSLog(@"%s src is nil", _cmd);
			break;
		}

		NSString* dst_path = [m_move_alert_textfield stringValue];
		NSLog(@"%s\nFROM: %@\nTO: %@", _cmd, src_path, dst_path);

		NSFileManager* fm = [NSFileManager defaultManager];
		
		NSError* error = nil;
		BOOL ok = [fm moveItemAtPath:src_path toPath:dst_path error:&error];
		if(ok) {
			NSLog(@"moved OK");
		} else {
			NSLog(@"ERROR: cannot move\n%@", error);
		}
		
	} while(0);
	
	[m_alert autorelease];
	m_alert = nil;

	[m_move_src_location autorelease];
	m_move_src_location = nil;

	[self reloadLeft];
	[self reloadRight];
	[m_left_pane rebuildInfo];
	[m_right_pane rebuildInfo];
	[self reloadLeft];
	[self reloadRight];
	[self reloadWindowTitle];
}

-(IBAction)newCopyAction:(id)sender {
	/*
	TODO: make the new copy sheet code work
	*/
	OFMPane* src = [self activePane];
	OFMPane* dest = [self inactivePane];

	NSArray* names = [src selectedNames];
	if([names count] == 0) {
		NSString* name = [src nameForCurrentRow];
		if(name == nil) {
			NSLog(@"AppDelegate %s ERROR: name is nil", _cmd);
			return;
		}
		names = [NSArray arrayWithObject:name];
	}
	
	[[KCCopySheet shared] loadBundle];
	[[KCCopySheet shared] setNames:names];
	[[KCCopySheet shared] setSourcePath:[src path]];
	[[KCCopySheet shared] setTargetPath:[dest path]];
	[[KCCopySheet shared] setParentWindow:m_window];
	[[KCCopySheet shared] showAskSheet];
}

-(IBAction)betterCopyAction:(id)sender {
	NSLog(@"%s", _cmd);
	if(m_copy == nil) {
		m_copy = [[JFCopy alloc] init];
		[m_copy load];
		[m_copy fillWithDummyData:self];
	}

	NSString* dest_dir = nil;
	NSString* source_dir = nil;

	OFMPane* src = [self activePane];
	OFMPane* dest = [self inactivePane];

	NSArray* names = [src selectedNames];
	if([names count] == 0) {
		NSString* name = [src nameForCurrentRow];
		if(name == nil) {
			NSLog(@"AppDelegate %s ERROR: name is nil", _cmd);
			return;
		}
		names = [NSArray arrayWithObject:name];
	}
	
	source_dir = [src path];
	dest_dir = [dest path];

	if((source_dir == nil) || (dest_dir == nil) || (names == nil)) {
		NSLog(@"%s ERROR: arguments are nil", _cmd);
		return;
	}


	[m_copy setSourcePath:source_dir];
	[m_copy setTargetPath:dest_dir];
	[m_copy setNames:names];

	[m_copy beginSheetForWindow:m_window];
	
}

-(IBAction)copyAction:(id)sender {
	NSTabView* tv = nil;
	NSString* src_path = nil;
	NSString* dst_path = nil;
	NSWindow* win = m_window;
	if([win firstResponder] == m_left_tableview) {
		tv = m_right_tabview;
		src_path = [m_left_pane pathForCurrentRow];
		dst_path = [m_right_pane path];
	}
	if([win firstResponder] == m_right_tableview) {
		tv = m_left_tabview;
		dst_path = [m_left_pane path];
		src_path = [m_right_pane pathForCurrentRow];
	}
	
	if(tv == nil) {
		return;
	}
	if(src_path == nil) {
		return;
	}
	if(dst_path == nil) {
		return;
	}
	// NSLog(@"%s\nfrom: %@\nto: %@", _cmd, src_path, dst_path);

	int index = [tv indexOfTabViewItem:[tv selectedTabViewItem]];
	if(index != 0) {
		return;
	}


	NSString* filename = [src_path lastPathComponent];
	NSString* suggested_path = [dst_path stringByAppendingPathComponent:filename];
    
	[m_copy_src_location autorelease];
	m_copy_src_location = [src_path retain];

	[m_alert autorelease];
	m_alert = nil;

	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"OK"];
	[alert addButtonWithTitle:@"Cancel"];
	[alert setMessageText:@"Copy file/dir"];
	[alert setInformativeText:@"What destination dir do you want it copied to."];
	[alert setAlertStyle:NSInformationalAlertStyle];
	
	[m_copy_alert_textfield setStringValue:suggested_path];
	[alert setAccessoryView:m_copy_alert_accessory];
	
	
	m_alert = alert;
	
	[alert beginSheetModalForWindow:m_window modalDelegate:self didEndSelector:@selector(copyAlertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
	[[alert window] makeFirstResponder:m_copy_alert_textfield];
}

-(void)copyAlertDidEnd:(NSAlert*)alert
            returnCode:(int)rc 
           contextInfo:(void*)ctx
{
	// NSLog(@"%s", _cmd);
	do {
		if(rc != NSAlertFirstButtonReturn) {
			NSLog(@"copy was cancelled by user");
			break;
		}

		NSLog(@"copying objects");

		NSString* src_path = m_copy_src_location;
		
		if(src_path == nil) {
			NSLog(@"%s src is nil", _cmd);
			break;
		}

		NSString* dst_path = [m_copy_alert_textfield stringValue];
		NSLog(@"%s\nFROM: %@\nTO: %@", _cmd, src_path, dst_path);

		NSFileManager* fm = [NSFileManager defaultManager];
		
		NSError* error = nil;
		BOOL ok = [fm copyItemAtPath:src_path toPath:dst_path error:&error];
		if(ok) {
			NSLog(@"copyed OK");
		} else {
			NSLog(@"ERROR: cannot copy\n%@", error);
		}
		
	} while(0);
	
	[m_alert autorelease];
	m_alert = nil;

	[m_copy_src_location autorelease];
	m_copy_src_location = nil;

	[self reloadLeft];
	[self reloadRight];
	[m_left_pane rebuildInfo];
	[m_right_pane rebuildInfo];
	[self reloadLeft];
	[self reloadRight];
	[self reloadWindowTitle];
}

-(IBAction)helpAction:(id)sender {
	NSString* bookname = [[NSBundle mainBundle] 
		objectForInfoDictionaryKey: @"CFBundleHelpBookName"];
	[[NSHelpManager sharedHelpManager] 
		openHelpAnchor:@"main_window" inBook:bookname];
}

-(IBAction)viewAction:(id)sender {
	// NSLog(@"%s", _cmd);
	NSWindow* win = m_window;
	if([win firstResponder] == m_left_tableview) {
		NSTabView* tv = m_right_tabview;
		int index = [tv indexOfTabViewItem:[tv selectedTabViewItem]];
		index = (index != 1) ? 1 : 0;
		[tv selectTabViewItemAtIndex:index];
		if(index == 1) {
			[self reloadQuickLook];
		}
	}
	if([win firstResponder] == m_right_tableview) {
		NSTabView* tv = m_left_tabview;
		int index = [tv indexOfTabViewItem:[tv selectedTabViewItem]];
		index = (index != 1) ? 1 : 0;
		[tv selectTabViewItemAtIndex:index];
		if(index == 1) {
			[self reloadQuickLook];
		}
	}
}

-(IBAction)editAction:(id)sender {
	[[self activePane] openFile];
}

-(BOOL)validateMenuItem:(NSMenuItem*)item {
    SEL action = [item action];

	if((action == @selector(moveAction:)) || 
		(action == @selector(copyAction:))) 
	{

		NSTabView* tv = nil;
		NSWindow* win = m_window;
		if([win firstResponder] == m_left_tableview) {
			tv = m_right_tabview;
		}
		if([win firstResponder] == m_right_tableview) {
			tv = m_left_tabview;
		}

		if(tv == nil) {
			return NO;
		}

		int index = [tv indexOfTabViewItem:[tv selectedTabViewItem]];
		if(index != 0) {
			return NO;
		}

		return YES;
	}

	return YES;
}

-(IBAction)reloadTab:(id)sender {
	// NSLog(@"%s", _cmd);
	[[self activePane] reloadPath];
}

-(IBAction)changeFontSizeAction:(id)sender {
	int tag = [sender tag];
	// NSLog(@"%s, %i", _cmd, tag);
	
	if(tag == 0) {
		m_table_font_size += 1;
	} else {
		m_table_font_size -= 1;
	}

	// NSLog(@"fontsize: %.2f", m_table_font_size);
	if(m_table_font_size < 8)  m_table_font_size = 8;
	if(m_table_font_size > 24) m_table_font_size = 24;

	int left_row = [m_left_pane row];
	int right_row = [m_right_pane row];
	
	[self syncFontSettings];

	[m_left_tableview scrollRowToVisible:left_row];
	[m_right_tableview scrollRowToVisible:right_row];
}

-(IBAction)restartDiscoverTaskAction:(id)sender {
	// [[self activePane] restartDiscoverTask];
}

-(IBAction)forceCrashDiscoverTaskAction:(id)sender {
	// [[self activePane] forceCrashDiscoverTask];
}

-(void)maybeShowDiscoverStatWindow {
	NSWindow* w = m_discover_stat_window;
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	if([defaults boolForKey:opcoders_show_discover_stat_window] == NO) {
		[w orderOut:self];
	} else {
		[w orderFront:self];
	}
}

-(void)maybeShowReportStatWindow {
	NSWindow* w = m_report_stat_window;
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	if([defaults boolForKey:opcoders_show_report_stat_window] == NO) {
		[w orderOut:self];
	} else {
		[w orderFront:self];
	}
}

-(IBAction)hideShowDiscoverStatWindowAction:(id)sender {
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSWindow* w = m_discover_stat_window;
	if([w isVisible]) {
		// NSLog(@"hide");
		[w orderOut:self];
		[defaults setBool:NO forKey:opcoders_show_discover_stat_window];
		return;
	}                    
	
	// NSLog(@"show");
	[w orderFront:self];
	[defaults setBool:YES forKey:opcoders_show_discover_stat_window];
}

-(IBAction)hideShowReportStatWindowAction:(id)sender {
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSWindow* w = m_report_stat_window;
	if([w isVisible]) {
		// NSLog(@"hide");
		[w orderOut:self];
		[defaults setBool:NO forKey:opcoders_show_report_stat_window];
		return;
	}                    
	
	// NSLog(@"show");
	[w orderFront:self];
	[defaults setBool:YES forKey:opcoders_show_report_stat_window];
}

- (void)windowWillClose:(NSNotification *)notification {
	// NSLog(@"%s", _cmd);
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	id thing = [notification object];
	if(thing == m_discover_stat_window) {
		[defaults setBool:NO forKey:opcoders_show_discover_stat_window];
	} 
	if(thing == m_report_stat_window) {
		[defaults setBool:NO forKey:opcoders_show_report_stat_window];
	} 
}

-(void)locateDiscoverAppExecutable {
	NSBundle* our_bundle = [NSBundle mainBundle];
	NSAssert(our_bundle, @"cannot find our bundle");
	NSString* path = [our_bundle pathForAuxiliaryExecutable:@"KCList"];

	NSFileManager* fm = [NSFileManager defaultManager];
	if([fm fileExistsAtPath:path] == NO) {
		NSRunAlertPanel(
			@"KCList is missing, cannot run program",
			@"Is supposed to be in the MacOS folder.",
			nil, nil, nil
		);
		[NSApp terminate:self];
	}

	m_path_to_discover_app_executable = [path retain];
}

-(void)locateReportAppExecutable {
	NSAssert(m_path_to_report_app_executable == nil, @"must not be initialized");
	
	NSString* executable =
		@"Report.app/Contents/MacOS/Report";

	NSString* path = nil;

	NSFileManager* fm = [NSFileManager defaultManager];
	NSString *cwd = [fm currentDirectoryPath];
	NSDictionary* env = [[NSProcessInfo processInfo] environment];
	NSArray* arg = [[NSProcessInfo processInfo] arguments];
	// NSLog(@"%@", cwd);
	// NSLog(@"%@", env);
	// NSLog(@"%@", arg);
	
	int backtrace_flags = 0;
	
	id thing = [env objectForKey:@"PATH_TO_REPORT_APP"];
	if([thing isKindOfClass:[NSString class]]) {
		backtrace_flags |= 1 << 0;
		/*
		In XCode under Executable "OrthodoxFileManager" Info
		you need to specify this environment variable
		
		ENV[PATH_TO_REPORT_APP] =
		/Report.app/Contents/MacOS/Report
		*/
		path = (NSString*)thing;
		if([path isAbsolutePath]) {
			backtrace_flags |= 1 << 4;
		} else {
			backtrace_flags |= 1 << 8;
			path = [cwd stringByAppendingPathComponent:path];
		}
		path = [path stringByResolvingSymlinksInPath];
	}

	if(!path) {
		backtrace_flags |= 1 << 12;
		NSBundle* our_bundle = [NSBundle mainBundle];
		// NSBundle* our_bundle = [NSBundle bundleForClass:[self class]];
		NSAssert(our_bundle, @"cannot find our bundle");
		NSString* resource_path = [our_bundle resourcePath];
		path = [resource_path stringByAppendingPathComponent:executable];
	}
	
	if([fm fileExistsAtPath:path] == NO) {
		NSLog(@"backend_executable %@", executable);
		NSLog(@"cwd %@", cwd);
		NSLog(@"environment %@", env);
		NSLog(@"arguments %@", arg);
		NSLog(@"backtrace_flags: %x", backtrace_flags);                
		NSLog(@"path: %@", path);
		NSLog(@"ERROR: cannot find the \"Report.app\" executable file");
		
		NSRunAlertPanel(
			@"Report.app is missing, cannot run program",
			@"Is supposed to be in the Resources folder. See console for details.",
			nil, nil, nil
		);

		[NSApp terminate:self];
		// NSAssert(NO, @"Report.app could not be found");
	}
	
	m_path_to_report_app_executable = [path retain];
}

-(void)locateCopyAppExecutable {
	NSAssert(m_path_to_copy_app_executable == nil, @"must not be initialized");
	
	NSString* executable =
		@"Copy.app/Contents/MacOS/Copy";

	NSString* path = nil;

	NSFileManager* fm = [NSFileManager defaultManager];
	NSString *cwd = [fm currentDirectoryPath];
	NSDictionary* env = [[NSProcessInfo processInfo] environment];
	NSArray* arg = [[NSProcessInfo processInfo] arguments];
	// NSLog(@"%@", cwd);
	// NSLog(@"%@", env);
	// NSLog(@"%@", arg);
	
	int backtrace_flags = 0;
	
	id thing = [env objectForKey:@"PATH_TO_COPY_APP"];
	if([thing isKindOfClass:[NSString class]]) {
		backtrace_flags |= 1 << 0;
		/*
		In XCode under Executable "OrthodoxFileManager" Info
		you need to specify this environment variable
		
		ENV[PATH_TO_COPY_APP] =
		/Copy.app/Contents/MacOS/Copy
		*/
		path = (NSString*)thing;
		if([path isAbsolutePath]) {
			backtrace_flags |= 1 << 4;
		} else {
			backtrace_flags |= 1 << 8;
			path = [cwd stringByAppendingPathComponent:path];
		}
		path = [path stringByResolvingSymlinksInPath];
	}

	if(!path) {
		backtrace_flags |= 1 << 12;
		NSBundle* our_bundle = [NSBundle mainBundle];
		// NSBundle* our_bundle = [NSBundle bundleForClass:[self class]];
		NSAssert(our_bundle, @"cannot find our bundle");
		NSString* resource_path = [our_bundle resourcePath];
		path = [resource_path stringByAppendingPathComponent:executable];
	}
	
	if([fm fileExistsAtPath:path] == NO) {
		NSLog(@"backend_executable %@", executable);
		NSLog(@"cwd %@", cwd);
		NSLog(@"environment %@", env);
		NSLog(@"arguments %@", arg);
		NSLog(@"backtrace_flags: %x", backtrace_flags);                
		NSLog(@"path: %@", path);
		NSLog(@"ERROR: cannot find the \"Copy.app\" executable file");
		
		NSRunAlertPanel(
			@"Copy.app is missing, cannot run program",
			@"Is supposed to be in the Resources folder. See console for details.",
			nil, nil, nil
		);

		[NSApp terminate:self];
		// NSAssert(NO, @"Report.app could not be found");
	}
	
	m_path_to_copy_app_executable = [path retain];
}

-(void)dumpVolumeInfoForPath:(NSString*)pathToFile {
	NSLog(@"%s path: %@", _cmd, pathToFile);
	const char* s = [pathToFile UTF8String];
	
	struct statfs64 st;
	int rc = statfs64(s, &st);
	if(rc != 0) {
		NSLog(@"%s error: statfs64 failed. %s", _cmd, strerror(errno));
		return;
	}
	NSLog(@"%s ok", _cmd);
	
	/*
	TODO: determine media type:  FTP, DiskImage, HardDisk, etc.
	TODO: determine local/remote
	TODO: determine volume name
	*/
	
	if(st.f_flags & MNT_RDONLY) {
		NSLog(@"%s read-only", _cmd);
	} else {
		NSLog(@"%s read-write", _cmd);
	}
	
	st.f_fstypename[MFSTYPENAMELEN-1] = 0;
	NSLog(@"%s fs-type: %s", _cmd, st.f_fstypename);
	
	st.f_mntonname[MAXPATHLEN-1] = 0;
	NSLog(@"%s fs-mount_on_name: %s", _cmd, st.f_mntonname);
	
	st.f_mntfromname[MAXPATHLEN-1] = 0;
	NSLog(@"%s fs-mount_from_name: %s", _cmd, st.f_mntfromname);
	
	
	uint64_t block_size = st.f_bsize;
	uint64_t number_of_block_total = st.f_blocks;
	uint64_t number_of_block_free = st.f_bfree;
	uint64_t fs_capacity = st.f_blocks * st.f_bsize / (1024 * 1024);
	uint64_t fs_avail = st.f_bfree * st.f_bsize / (1024 * 1024);
	
	double h_capacity = fs_capacity / 1024.0;
	double h_avail = fs_avail / 1024.0;
	
	double avail_pc = 0;
	if(fs_capacity > 100) {
		avail_pc = double(fs_avail) * 100.0 / double(fs_capacity);
	}
	NSLog(@"%s block_size: %i", _cmd, (int)st.f_bsize);
	NSLog(@"%s blocks total: %i", _cmd, (int)st.f_blocks);
	NSLog(@"%s blocks free: %i", _cmd, (int)st.f_bfree);
	NSLog(@"%s capacity: %.2f", _cmd, h_capacity);
	NSLog(@"%s avail: %.2f (%3.f)", _cmd, h_avail, avail_pc);
	

	unsigned long long sizeValue;
	NSNumber *keyValue;
	NSString* fullPath = [pathToFile stringByStandardizingPath];
    if (fullPath) {
		NSFileManager *fm = [NSFileManager defaultManager];
        NSDictionary *fileSystemAttributes = [fm fileSystemAttributesAtPath:fullPath];
        if (fileSystemAttributes && [fileSystemAttributes count]) {
			keyValue = [fileSystemAttributes objectForKey:NSFileSystemFreeSize];
            if (keyValue) {
                sizeValue = [keyValue unsignedLongLongValue];
                 NSLog(@"The current free space on the volume containing \"%@\" is %qu", fullPath, sizeValue);
				NSLog(@"%s systemattrs: %@", _cmd, fileSystemAttributes);
            }
        }
    }
}

-(IBAction)debugAction:(id)sender {
	int tag = [sender tag];
	NSLog(@"%s tag=%i", _cmd, tag);
	
	if(tag == 1) {
		NSString* path = [[self activePane] pathForCurrentRow];
		NSLog(@"%s path: %@", _cmd, path);
	} else 
	if(tag == 2) {
		NSString* path = [[self activePane] pathForCurrentRow];
		[self dumpVolumeInfoForPath:path];
	}
#if 0
	if(tag == 2) {

		NSError* error = nil;
		SFAuthorization* authorization = [SFAuthorization authorization];
		BOOL ok =
			[authorization
				obtainWithRights:NULL
				flags:kAuthorizationFlagExtendRights
				environment:NULL
				authorizedRights:NULL
				error:&error];
		if(!ok) {
			NSLog(@"SFAuthorization error: %@", [error localizedDescription]); 
			authorization = nil;
			return;
		}
		NSLog(@"%s authorization granted", _cmd);
		
		/*
		instead of NSTask you must use AuthorizationExecuteWithPrivileges()
		to run as superuser.
		*/
	}
#endif
}

-(IBAction)debugInspectCacheAction:(id)sender {
	NSLog(@"%@", [DirCache shared]);
}

-(IBAction)debugSeparatorAction:(id)sender {
	printf("\n-------------------------\n\n");
	fflush(stdout);
}

-(void)cleanupCache {
	// NSLog(@"%s", _cmd);
	[[DirCache shared] resetMarks];
	
	[m_left_pane markCacheItems];
	[m_right_pane markCacheItems];

	[[DirCache shared] removeUnmarkedItems];
}

-(IBAction)selectAllAction:(id)sender {
	[[self activePane] selectAll];
}

-(IBAction)selectNoneAction:(id)sender {
	[[self activePane] selectNone];
}

-(IBAction)selectAllOrNoneAction:(id)sender {
	[[self activePane] selectAllOrNone];
}

-(IBAction)invertSelectionAction:(id)sender {
	[[self activePane] invertSelection];
}

-(IBAction)copyCurrentPathStringToClipboardAction:(id)sender {
	OFMPane* pane = [self activePane];
	if(pane == nil) return;

	NSString* path = [pane pathForCurrentRow];
	if(path == nil) path = [pane path];

	// NSLog(@"path: %@", path);
	if(path == nil) return;
	
	NSPasteboard* pb = [NSPasteboard generalPasteboard];
	[pb declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
	[pb setString:path forType:NSStringPboardType];
}

-(void)applicationWillTerminate:(NSNotification *)aNotification {
	// NSLog(@"%s", _cmd);
}

/*
called from osascript when we within Finder 
ask to revealing files in our program 
*/
- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames {
/*	NSRunAlertPanel(
		@"openFiles:", 
		[NSString stringWithFormat:@"files: %@", filenames],
		nil, nil, nil
	);*/
	if([filenames count] > 0) {
		[[self activePane] appToOpenPath:[filenames objectAtIndex:0]];
	}
}

/*- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
	NSRunAlertPanel(
		@"openFile:", 
		filename,
		nil, nil, nil
	);
	return YES;
}*/

/*- (BOOL)application:(id)sender openFileWithoutUI:(NSString *)filename {
	NSRunAlertPanel(
		@"openFileWithoutUI:", 
		filename,
		nil, nil, nil
	);
	return YES;
}*/

/*- (BOOL)application:(NSApplication *)theApplication openTempFile:(NSString *)filename {
	NSRunAlertPanel(
		@"openTempFile:", 
		filename,
		nil, nil, nil
	);
	return YES;
}*/

-(IBAction)openDiffToolAction:(id)sender {
	NSLog(@"%s", _cmd);
	NSString* launch_path = @"/usr/bin/opendiff";
	NSString* path1 = [[self activePane] pathForCurrentRow];
	NSString* path2 = [[self inactivePane] pathForCurrentRow];
	
	if(path1 == nil) return;
	if(path2 == nil) return;

	NSArray* task_args = [NSArray arrayWithObjects:
		path1, path2, nil
	];
	NSTask* task = [[NSTask alloc] init];
	[task setLaunchPath:launch_path];
	[task setArguments:task_args];
	[task launch];
	[task waitUntilExit];
	[task release];
}

-(void)waitUntilNoKeysArePressed {
	/*
	because Terminal.app is very sensitive to what keys are pressed
	when you start it from osascript. It's necessary to wait until
	no keys are pressed, so that we don't confuse Terminal.app.
	*/
	NSEvent* event = [NSApp currentEvent];
	int keymask = 
		NSShiftKeyMask | 
		NSControlKeyMask | 
		NSAlternateKeyMask | 
		NSCommandKeyMask;
    while(1) {
		unsigned int mods = [event modifierFlags];
		// NSLog(@"%s modifiers: %i", _cmd, mods);
		
		if((mods & keymask) == 0) break;

		// NSLog(@"waiting");
        event = [m_window nextEventMatchingMask:NSAnyEventMask];
	}
	// NSLog(@"%s all keys are up now", _cmd);
}

-(IBAction)openCurrentPathInTerminalAction:(id)sender {
	NSString* dir_to_open = [[self activePane] path];
	// NSLog(@"%s path: %@", _cmd, dir_to_open);

	/*
	ARGH Terminal.app is very sensitive to what keys that are
	being held down when you start it. So if you still hold
	down either 't' or CMD or ALT or SHIFT.. it will act on it.

	we must wait to make sure we don't confuse Terminal.app.
	If it sees keydown when you use osascript it 
	doesn't do what you want it to do.
	*/
	[self waitUntilNoKeysArePressed];

	int tag = [sender tag];
	if(tag == 0) {
		// NSLog(@"%s overwrite current path in frontmost terminal", _cmd);
		[self terminalSetToDir:dir_to_open];
	} else
	if(tag == 1) {
		// NSLog(@"%s open in new window", _cmd);
		[self terminalNewWindowWithDir:dir_to_open];
	} else {
		// NSLog(@"%s open in new tab", _cmd);
		[self terminalNewTabWithDir:dir_to_open];
	}
}

-(void)terminalNewWindowWithDir:(NSString*)dir_to_open {
	NSString* script = @""
	"on run argv\n"
	"  set dir_to_open to item 1 of argv\n"
	"  set cd_to_dir to \"cd \" & quoted form of dir_to_open\n"
/*	"  tell application \"Finder\"\n"
	"    activate\n"
	"    display dialog \"The argument is \" & dir_to_open\n"
	"  end tell\n" /**/
	"  tell application \"Terminal\"\n"
	"    activate\n"
	"    do script cd_to_dir\n"
	"  end tell\n"
	"end run\n";
	NSArray* args = [NSArray arrayWithObjects:@"-", dir_to_open, nil];
	[self runAppleScript:script arguments:args];
}

-(void)terminalNewTabWithDir:(NSString*)dir_to_open {
	NSString* script = @""
	"on run argv\n"
	"  set dir_to_open to item 1 of argv\n"
	"  set cd_to_dir to \"cd \" & quoted form of dir_to_open\n"
/*	"  tell application \"Finder\"\n"
	"    activate\n"
	"    display dialog \"The argument is \" & dir_to_open\n"
	"  end tell\n" /**/
	"  tell application \"Terminal\"\n"
	"    activate\n"
	"    tell application \"System Events\" to "
	       "tell process \"Terminal\" to "
	       "keystroke \"t\" using command down\n"
	"    do script cd_to_dir in window 1\n"
	"  end tell\n"
	"end run\n";
	NSArray* args = [NSArray arrayWithObjects:@"-", dir_to_open, nil];
	[self runAppleScript:script arguments:args];
}

-(void)terminalSetToDir:(NSString*)dir_to_open {
	NSString* script = @""
	"on run argv\n"
	"  set dir_to_open to item 1 of argv\n"
	"  set cd_to_dir to \"cd \" & quoted form of dir_to_open\n"
/*	"  --tell application \"Finder\"\n"
	"  --  activate\n"
	"  --  display dialog \"The argument is \" & dir_to_open\n"
	"  --end tell\n" /**/
	"  tell application \"Terminal\"\n"
	"    if (count of windows) is 0 then\n"
	"      do script cd_to_dir\n"
	"    else\n"
	"      if window 1 is not busy then\n"
	"        do script cd_to_dir in window 1\n"
	"      else\n"
	"        do script cd_to_dir\n"
	"      end if\n"
	"    end if	\n"
	"  activate\n"
	"  end tell\n"
	"end run\n";
	NSArray* args = [NSArray arrayWithObjects:@"-", dir_to_open, nil];
	[self runAppleScript:script arguments:args];
}

-(void)runAppleScript:(NSString*)script arguments:(NSArray*)arguments {
	NSTask* t = [[[NSTask alloc] init] autorelease];
	NSPipe* p = [NSPipe pipe];
	[t setLaunchPath:@"/usr/bin/osascript"];
	[t setArguments:arguments];
	[t setStandardInput:p];
	NSFileHandle* fh = [p fileHandleForWriting];
	[t launch];
	[fh writeData:[script dataUsingEncoding:NSUTF8StringEncoding
	allowLossyConversion:YES]];
	[fh closeFile];
	[t waitUntilExit];
}

-(IBAction)showReportAction:(id)sender {
	// NSLog(@"%s", _cmd);
	NSWindow* win = m_window;
	if([win firstResponder] == m_left_tableview) {
		NSTabView* tv = m_right_tabview;
		int index = [tv indexOfTabViewItem:[tv selectedTabViewItem]];
		index = (index != 2) ? 2 : 0;
		[tv selectTabViewItemAtIndex:index];
		if(index == 2) {
			[self reloadReport];
		}
	}
	if([win firstResponder] == m_right_tableview) {
		NSTabView* tv = m_left_tabview;
		int index = [tv indexOfTabViewItem:[tv selectedTabViewItem]];
		index = (index != 2) ? 2 : 0;
		[tv selectTabViewItemAtIndex:index];
		if(index == 2) {
			[self reloadReport];
		}
	}
}

-(void)reportDidLaunch {
	// NSLog(@"AppDelegate %s", _cmd);
	[self reloadReport];
}

-(void)reportIsNowProcessingTheRequest {
	// NSLog(@"AppDelegate %s BEFORE", _cmd);
	 
	double t = CFAbsoluteTimeGetCurrent();
	m_time_report_processing = t;
	double diff = t - m_time_report_begin;
	[m_report_stat_item setMessage:@"hang 1"];
	[m_report_stat_item setTime0:diff];

	// NSLog(@"AppDelegate %s AFTER", _cmd);
}

-(void)reportHasData:(NSData*)data {
	// NSLog(@"AppDelegate %s", _cmd);

	double t = CFAbsoluteTimeGetCurrent();
	double diff = t - m_time_report_processing;

	NSString* s = [NSString stringWithFormat:@"OK %.3f", float(t - m_time_report_begin)];
	[m_report_stat_item setMessage:s];
	[m_report_stat_item setTime1:diff];

	id thing = [NSUnarchiver unarchiveObjectWithData:data];
	if([thing isKindOfClass:[NSAttributedString class]] == NO) {
		NSLog(@"ERROR: unknow data");
		return;
	}
	
	NSAttributedString* as = (NSAttributedString*)thing;

	NSTextView* report = nil;
	NSTabView* tv = nil;

	NSWindow* win = m_window;
	if([win firstResponder] == m_left_tableview) {
		report = m_right_report_textview;
		tv = m_right_tabview;
	}
	if([win firstResponder] == m_right_tableview) {
		report = m_left_report_textview;
		tv = m_left_tabview;
	}
	
	if(report == nil) {
		return;
	}
	int index = [tv indexOfTabViewItem:[tv selectedTabViewItem]];
	if(index != 2) {
		return;
	}

	[[report textStorage] setAttributedString:as];
}

-(void)reloadReport {
	// NSLog(@"%s", _cmd);

	NSString* path = nil;   
	NSTextView* report = nil;
	NSTabView* tv = nil;

	NSWindow* win = m_window;
	if([win firstResponder] == m_left_tableview) {
		path = [m_left_pane pathForReport];
		report = m_right_report_textview;
		tv = m_right_tabview;
	}
	if([win firstResponder] == m_right_tableview) {
		path = [m_right_pane pathForReport];
		report = m_left_report_textview;
		tv = m_left_tabview;
	}
	
	if(path == nil) {
		NSLog(@"AppDelegate %s ERROR: path is nil", _cmd);
		return;
	}
	if(report == nil) {
		return;
	}
	int index = [tv indexOfTabViewItem:[tv selectedTabViewItem]];
	if(index != 2) {
		return;
	}

    // NSLog(@"%s: %@", _cmd, path);

	{
		double t = CFAbsoluteTimeGetCurrent();
		m_time_report_begin = t;
		int timestamp_i = (int)t;
		if(timestamp_i > 0) timestamp_i = timestamp_i % 1000;
		NSString* ts = [NSString stringWithFormat:@"%03i", timestamp_i];
		KCReportStatItem* item = [[[KCReportStatItem alloc] init] autorelease];
		[item setTimestamp:ts];
		[item setPath:path];  
		[item setMessage:@"hang 0"];
		[m_report_stat_items addObject:item];

		[m_report_stat_item autorelease];
		m_report_stat_item = [item retain];

		// remove old entries, so we have 10 rows of recent stats
		NSArray* ary = [m_report_stat_items content];
		int n = [ary count];
		if(n > 10) {
			NSRange range = NSMakeRange(n - 10, 10);
			ary = [[ary subarrayWithRange:range] mutableCopy];
			// NSLog(@"%s clamp", _cmd);
			[m_report_stat_items setContent:ary];
		}
	}

	if(m_report == nil) {
		NSAttributedString* as = [[[NSAttributedString alloc] initWithString:@"Loading..."] autorelease];
		[[report textStorage] setAttributedString:as];
		

		m_report = [[KCReport alloc] 
			initWithName:@"main" 
			path:m_path_to_report_app_executable
		];
	
		[m_report setDelegate:self];

		[m_report start];
		return;
	}
	
	[m_report requestPath:path];
}

-(IBAction)installCommandlineToolAction:(id)sender {
	NSLog(@"%s", _cmd);

	int path_capacity = 2000;
	char path_installcmdtools[2000];
	char path_kc[2000];

    CFBundleRef bundle = CFBundleGetMainBundle();
    assert(bundle != NULL);

    {
		CFStringRef exe_name = CFSTR("InstallCmdTools");
	    CFURLRef url_to_exe = CFBundleCopyAuxiliaryExecutableURL(bundle, exe_name);
	    Boolean success = CFURLGetFileSystemRepresentation(
			url_to_exe, true, (UInt8*)path_installcmdtools, path_capacity);
		assert(success);
	}
    {
		CFStringRef exe_name = CFSTR("jf");
	    CFURLRef url_to_exe = CFBundleCopyAuxiliaryExecutableURL(bundle, exe_name);
	    Boolean success = CFURLGetFileSystemRepresentation(
			url_to_exe, true, (UInt8*)path_kc, path_capacity);
		assert(success);
	}
	
	char* copy_src = path_kc;
	char* copy_dest = "/usr/bin/jf";
    
    AuthorizationRef auth;

    OSStatus rc = AuthorizationCreate(NULL, NULL, kAuthorizationFlagDefaults, &auth);
    assert(rc == noErr);

	FILE* fd = NULL; // file descriptor
	char* args[] = {copy_src, copy_dest, NULL};

	rc = AuthorizationExecuteWithPrivileges(
		auth,
	    path_installcmdtools,
		kAuthorizationFlagDefaults, 
		args,
	    &fd
	);
	if(rc == noErr) {
		char buffer[1024];
		while(1) {
	        if(fgets(buffer, sizeof(buffer)-1, fd) == NULL) {
				break;
			}
			buffer[sizeof(buffer)-1] = 0;
			printf("read: %s", buffer);
		}

		if(fd != NULL) {
			fclose(fd);
		}
	} else {
		NSLog(@"%s aborted authorized exe: %i", _cmd, (int)rc);
	}


	AuthorizationFree(auth, kAuthorizationFlagDestroyRights);
}

-(IBAction)showAboutPanel:(id)sender {
	if(m_about_window == nil) {
		[NSBundle loadNibNamed:@"AboutPanel" owner:self];
		
		{
			NSString* v = [[NSBundle mainBundle] 
				objectForInfoDictionaryKey: @"CFBundleVersion"];
		    if(v != nil) {
				[m_about_version_textfield setStringValue:v];
			}
		}
		{
			NSString* v = [[NSBundle mainBundle] 
				objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
		    if(v != nil) {
				[m_about_shortversion_textfield setStringValue:v];
			}
		}
		{
			NSString* v = [[NSBundle mainBundle] 
				objectForInfoDictionaryKey: @"CFBundleName"];
		    if(v != nil) {
				[m_about_name_textfield setStringValue:v];
			}
		}
		if(1) { // for some reason when reading the plist.. this key has been swapped!
			NSString* v = [[NSBundle mainBundle] 
				objectForInfoDictionaryKey: @"NSHumanReadableCopyright"];
		    if(v != nil) {
				[m_about_copyright_textfield setStringValue:v];
			}
		}
	}
	[m_about_window center];
    [m_about_window makeKeyAndOrderFront:nil];
}

-(IBAction)donateMoneyAction:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:
		@"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=7465143"]];
}

-(IBAction)visitWebsiteAction:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:
		@"http://opcoders.com"]];
}

-(IBAction)showPreferencesPanel:(id)sender {
	MBPreferencesController* mc = [MBPreferencesController sharedController];
	if([[mc modules] count] == 0) {
		JFGeneralPrefController* mod0 = [[JFGeneralPrefController alloc] initWithNibName:@"PreferencesGeneral" bundle:nil];
		JFActionPrefController* mod1 = [[JFActionPrefController alloc] initWithNibName:@"PreferencesAction" bundle:nil];
		JFBookmarkPrefController* mod2 = [[JFBookmarkPrefController alloc] initWithNibName:@"PreferencesBookmark" bundle:nil];
		JFIgnorePrefController* mod3 = [[JFIgnorePrefController alloc] initWithNibName:@"PreferencesIgnore" bundle:nil];
		[[MBPreferencesController sharedController] setModules:[NSArray arrayWithObjects:mod0, mod1, mod2, mod3, nil]];
		[mod0 release];
		[mod1 release];          
		[mod2 release];                  
		[mod3 release];
	}
	[[MBPreferencesController sharedController] showWindow:sender];
}

-(void)customizeActionMenu {
	[self showPreferencesPanel:self];
	
	id<MBPreferencesModule> thing = 
		[[MBPreferencesController sharedController]
		 	moduleForIdentifier:@"ActionPane"];
		
	// NSLog(@"%s thing: %@", _cmd, thing);
	if(thing != nil) {
		[[MBPreferencesController sharedController] 
			changeToModule:thing animate:NO];
	}
}

-(void)customizeBookmarkMenu {
	[self showPreferencesPanel:self];
	
	id<MBPreferencesModule> thing = 
		[[MBPreferencesController sharedController]
		 	moduleForIdentifier:@"BookmarkPane"];
		
	// NSLog(@"%s thing: %@", _cmd, thing);
	if(thing != nil) {
		[[MBPreferencesController sharedController] 
			changeToModule:thing animate:NO];
	}
}

-(IBAction)showBookmarkPreferencesPanel:(id)sender {
	[self customizeBookmarkMenu];
}

-(void)dealloc {
	[m_left_pane release];
	[m_right_pane release];
	[m_alert release];
	
	[m_report release];
	
    [super dealloc];
}

@end
