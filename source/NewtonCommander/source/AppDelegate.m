//
//  NewtonCommanderAppDelegate.m
//  NewtonCommander
//
//  Created by Simon Strandgaard on 24/01/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "AppDelegate.h"
#import "NCMainWindowController.h"
#import "NCDualPane.h"
#import "MBPreferencesController.h"
#import "NCPreferencesGeneralController.h"
#import "NCPreferencesAdvancedController.h"
#import "NCPreferencesMenuController.h"
#import "NCPreferencesBookmarkController.h"
#import "NCLog.h"
#import "NCCommon.h"
#include <sys/stat.h>
// Carbon included for help API 
#include <Carbon/Carbon.h>

#include <sys/types.h>
#include <dirent.h>

#if 0
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
BOOL register_my_help_book() {
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
    return YES;

bail:
    if (myBundleURL != NULL) CFRelease(myBundleURL);
    return NO;
}
#endif




static void * const kNCUserDefaultBookmarkItemsContext = (void*)&kNCUserDefaultBookmarkItemsContext;


@interface NSString (HFSUnicodeString)

+ (NSString*)stringWithHFSUnicodeStr255:(const HFSUniStr255*)str;
- (void)getHFSUnicodeStr255:(HFSUniStr255*)str;

@end

@implementation NSString (HFSUnicodeString)

+(NSString*)stringWithHFSUnicodeStr255:(const HFSUniStr255*)str {
    return ([NSString stringWithCharacters:str->unicode length:str->length]);
}

-(void)getHFSUnicodeStr255:(HFSUniStr255*)str {
    NSAssert1(str->length<=255,@"HFS Unicode string too long (%d)",str->length);
    str->length = [self length];
    [self getCharacters:str->unicode];
}
@end






@interface AppDelegate (Private)
-(void)test;
-(void)rebuildBookmarkMenu;
-(void)repairPermissions;
-(BOOL)isWorkerInstalled;
@end

@implementation AppDelegate

+ (void)initialize {
	/*
	Set up initial values for defaults
	*/
    NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
    
    [dictionary setObject:@"Lucida Grande" forKey:@"FontPreset"];
    
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:dictionary];
}

-(id)init {
	if ((self = [super init]) != nil) {
		{
			// as the very first thing we initialize the logging code, so we can debug
		  	[NCLog setupNewtonCommander];   

			// LOG_ERROR(@"test error <---------------");
			// LOG_WARNING(@"test warning <---------------");
			// LOG_DEBUG(@"test debug <---------------");
		}

		[self test];


		if([self isWorkerInstalled]) {
			// LOG_DEBUG(@"yay, it's installed");
		} else {
			LOG_DEBUG(@"NCWorker is not installed, type in your password and have it installed");
			[self repairPermissions];

			if([self isWorkerInstalled]) {
				LOG_DEBUG(@"yay, it's now installed");
			} else {
				LOG_DEBUG(@"nope, not installed correctly");
			}
		}
	}
	return self;
}

-(void)test {
#if 0
	struct dirent* dp = NULL;
	DIR* dirp = opendir("/");
	while ((dp = readdir(dirp)) != NULL) {
		NSLog(@"%s readdir: %s", _cmd, dp->d_name);
	}
	(void)closedir(dirp);
#endif 
#if 0
	LOG_DEBUG(@"%s creating custom fork", _cmd);
	NSString* path = @"/Volumes/AnalyzeCopySource/group0/AnalyzeCopy-Volume";
	FSRef ref;
	Boolean isDirectory;
	if(FSPathMakeRef((const UInt8 *)[path fileSystemRepresentation], &ref, &isDirectory) != noErr) {
		LOG_DEBUG(@"%s couldn't create FSRef", _cmd);
		return;
	}
	
	HFSUniStr255 forkname;
	[@"TEST" getHFSUnicodeStr255:&forkname];
	OSErr err;
	err = FSCreateFork(&ref, forkname.length, forkname.unicode);
	if(err == errFSBadForkName) {
		LOG_DEBUG(@"%s couldn't create fork (errFSBadForkName)", _cmd);
		return;
	}
	if(err != noErr) {
		LOG_DEBUG(@"%s couldn't create fork (other)", _cmd);
		return;
	}

	LOG_DEBUG(@"%s fork created!", _cmd);
#endif	
}

/*-(IBAction)repairPermissionsAction:(id)sender {
	LOG_DEBUG(@"called");
	[self repairPermissions];
}*/

-(BOOL)isWorkerInstalled {
	NSBundle* bundle = [NSBundle mainBundle];
	NSAssert(bundle, @"cannot find our bundle");
	NSString* path_to_worker = [bundle pathForAuxiliaryExecutable:@"NewtonCommanderHelper"];
	const char* stat_path = [path_to_worker fileSystemRepresentation];

	struct stat st;
	int rc = stat(stat_path, &st);
	int err = 0;
	
	if(rc == -1) {
		err |= 1; // cannot stat the file.  no such file
	} else {
		if(!S_ISREG(st.st_mode))      err |= 2;  // not a file
		if(st.st_uid != 0)            err |= 4;  // uid is not root
		if(st.st_gid != 0)            err |= 8;  // gid is not wheel
		if((st.st_mode & 04000) == 0) err |= 16; // setuid bit is not set
		if((st.st_mode & 0100) == 0)  err |= 32; // execute bit is not set
	}
	if(err) {
		LOG_ERROR(@"Worker is not installed. Code: %i  path: %@", err, path_to_worker);
	}
	return (err == 0);
}

-(void)repairPermissions {

	int path_capacity = 2000;
	char path_install[2000];
	char path_worker[2000];

    CFBundleRef bundle = CFBundleGetMainBundle();
    assert(bundle != NULL);

    {
		CFStringRef exe_name = CFSTR("install.sh");
	    CFURLRef url_to_exe = CFBundleCopyAuxiliaryExecutableURL(bundle, exe_name);
	    Boolean success = CFURLGetFileSystemRepresentation(
			url_to_exe, true, (UInt8*)path_install, path_capacity);
		assert(success);
	}
    {
		CFStringRef exe_name = CFSTR("NewtonCommanderHelper");
	    CFURLRef url_to_exe = CFBundleCopyAuxiliaryExecutableURL(bundle, exe_name);
	    Boolean success = CFURLGetFileSystemRepresentation(
			url_to_exe, true, (UInt8*)path_worker, path_capacity);
		assert(success);
	}
	LOG_DEBUG(@"install: %s", path_install);
	LOG_DEBUG(@"worker: %s", path_worker);
	
    AuthorizationRef auth;

    OSStatus rc = AuthorizationCreate(NULL, NULL, kAuthorizationFlagDefaults, &auth);
    assert(rc == noErr);

	FILE* fd = NULL; // file descriptor
	char* args[] = {path_install, path_worker, NULL};
	
    /* TODO: AuthorizationExecuteWithPrivileges() is deprecated, use SMJobBless() instead
     * see http://stackoverflow.com/questions/6841937/authorizationexecutewithprivileges-is-deprecated
     */
	rc = AuthorizationExecuteWithPrivileges(
		auth,
	    "/bin/sh",
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
			LOG_DEBUG(@"read: %s", buffer);
		}

		if(fd != NULL) {
			fclose(fd);
		}
	} else {
		LOG_ERROR(@"aborted authorized exe: %i", (int)rc);
	}

	AuthorizationFree(auth, kAuthorizationFlagDestroyRights);
}

-(IBAction)newDocument:(id)sender
{	
	if (myWindowController == nil)
		myWindowController = [[NCMainWindowController alloc] initWithWindowNibName:@"MainWindow"];
	
	[myWindowController showWindow:self];
}


// -------------------------------------------------------------------------------
//	applicationDidFinishLaunching:notification
// -------------------------------------------------------------------------------
- (void)applicationDidFinishLaunching:(NSNotification*)notification
{
	[self newDocument:self];

	[self rebuildBookmarkMenu];

	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self 
		forKeyPath:@"values.kNCUserDefaultBookmarkItems" 
		options:NSKeyValueObservingOptionNew 
		context:kNCUserDefaultBookmarkItemsContext];

/*	if(!register_my_help_book()) {
		LOG_ERROR(@"failed registering help book");
	}*/

}

- (void)applicationWillTerminate:(NSNotification*)notification {
	[myWindowController save];
}


- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context
{
	// LOG_DEBUG(@"keypath: %@", keyPath);
	if (context == kNCUserDefaultBookmarkItemsContext) {
		// LOG_DEBUG(@"%s preferences has changed", _cmd);
		[self rebuildBookmarkMenu];
		return;
	}
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

-(void)rebuildBookmarkMenu {
	NSArray* items = [NCUserDefaultBookmarkItem loadDefaultItems];
	// LOG_DEBUG(@"%s items: %@", _cmd, items);

	NSMenu* menu = m_bookmarks_menu;

	{
		// wipe all menu items
		int count = [menu numberOfItems];
		for(int i=count-1; i>=0; --i) {
			[menu removeItemAtIndex:i];
		}
	}

	{
		NSMenuItem* mi = [[NSMenuItem alloc] initWithTitle:@"Bookmark This Dir" action:@selector(bookmarkThisDirAction:) keyEquivalent:@"d"];
		[mi setKeyEquivalentModifierMask:NSCommandKeyMask];
		[mi setTarget:self];
		[menu addItem:mi];
	}

	[menu addItem:[NSMenuItem separatorItem]];

	NSString* shortcut_lut[] = {
		@"1", @"2", @"3", @"4", @"5",
		@"6", @"7", @"8", @"9", @"0",
	};

	int n = [items count];
	for(int j=0; j<10; ++j)
	for(int i=0; i<3; ++i) {
		int index = i * 10 + j;
		if(index >= n) continue;
		// LOG_DEBUG(@"%s %i", _cmd, index);

		id thing = [items objectAtIndex:index];
		if([thing isKindOfClass:[NCUserDefaultBookmarkItem class]] == NO) {
			continue;
		}
		NCUserDefaultBookmarkItem* bmi = (NCUserDefaultBookmarkItem*)thing;

		NSString* s = shortcut_lut[j];
		NSUInteger mask = NSCommandKeyMask;
		BOOL alternate = NO;
		if(i == 1) {
			mask |= NSAlternateKeyMask;
			alternate = YES;
		} else
		if(i == 2) {
			mask |= NSControlKeyMask;
			alternate = YES;
		}

		NSMenuItem* mi = [[NSMenuItem alloc] initWithTitle:[bmi name]
			action:@selector(bookmarkMenuAction:) keyEquivalent:s];
		[mi setKeyEquivalentModifierMask:mask];
		[mi setAlternate:alternate];
		[mi setRepresentedObject:[bmi path]];
		[mi setTarget:self];
		[menu addItem:mi];
	}
	
	[menu addItem:[NSMenuItem separatorItem]];

	{
		NSMenuItem* mi = [[NSMenuItem alloc] initWithTitle:@"Customize…" action:@selector(showBookmarkPaneInPreferencesPanel:) keyEquivalent:@"b"];
		[mi setKeyEquivalentModifierMask:NSCommandKeyMask | NSAlternateKeyMask];
		[mi setTarget:self];
		[menu addItem:mi];
	}
}

-(void)bookmarkMenuAction:(id)sender {
	id thing = [sender representedObject];
	if([thing isKindOfClass:[NSString class]] == NO) {
		return;
	}
	NSString* path = (NSString*)thing;
	// LOG_DEBUG(@"go to bookmark: %@", path);
	[myWindowController setActiveWorkingDir:path];
}

-(void)bookmarkThisDirAction:(id)sender {
	NSString* path = [myWindowController activeWorkingDir];
	// LOG_DEBUG(@"path: %@", path);
	NCUserDefaultBookmarkItem* item = [[NCUserDefaultBookmarkItem alloc] init];
	[item setPath:path];
	[item setName:[path lastPathComponent]];

	NSArray* items = [NCUserDefaultBookmarkItem loadDefaultItems];
	items = [items arrayByAddingObject:item];
	[NCUserDefaultBookmarkItem saveDefaultItems:items];

	MBPreferencesController* ctrl = [MBPreferencesController sharedController];
	id<MBPreferencesModule> thing = [ctrl moduleForIdentifier:@"BookmarkPane"];
		
	// LOG_DEBUG(@"thing: %@", thing);
	if(thing != nil) {
		// LOG_DEBUG(@"loadUserDefaults");
		[(NCPreferencesBookmarkController*)thing loadUserDefaults];
	}
}


// -------------------------------------------------------------------------------
//	validateMenuItem:theMenuItem
// -------------------------------------------------------------------------------
-(BOOL)validateMenuItem:(NSMenuItem*)theMenuItem
{
    BOOL enable = [self respondsToSelector:[theMenuItem action]];

    // disable "New" if the window is already up
	if ([theMenuItem action] == @selector(newDocument:))
	{
		if ([[myWindowController window] isKeyWindow])
			enable = NO;
	}
	return enable;
}

// -------------------------------------------------------------------------------
//	help
// -------------------------------------------------------------------------------

-(IBAction)showHelp:(id)sender {
	LOG_DEBUG(@"called");
	NSString* bookname = [[NSBundle mainBundle] 
		objectForInfoDictionaryKey: @"CFBundleHelpBookName"];
	[[NSHelpManager sharedHelpManager] 
		openHelpAnchor:@"main_window" inBook:bookname];
}



// -------------------------------------------------------------------------------
//	preferences
// -------------------------------------------------------------------------------

-(IBAction)showPreferencesPanel:(id)sender {
	MBPreferencesController* ctrl = [MBPreferencesController sharedController];
	if([[ctrl modules] count] == 0) {
		NSBundle* b = [NSBundle bundleForClass:[MBPreferencesController class]];
		NSAssert(b, @"must be in the framework bundle");
		NCPreferencesGeneralController* mod0 = [[NCPreferencesGeneralController alloc] initWithNibName:@"PreferencesGeneral" bundle:b];
		NCPreferencesLeftMenuController* mod1 = [[NCPreferencesLeftMenuController alloc] initWithNibName:@"PreferencesMenu" bundle:b];
		NCPreferencesRightMenuController* mod2 = [[NCPreferencesRightMenuController alloc] initWithNibName:@"PreferencesMenu" bundle:b];
		NCPreferencesBookmarkController* mod3 = [[NCPreferencesBookmarkController alloc] initWithNibName:@"PreferencesBookmark" bundle:b];
		NCPreferencesAdvancedController* mod4 = [[NCPreferencesAdvancedController alloc] initWithNibName:@"PreferencesAdvanced" bundle:b];
		[ctrl setModules:[NSArray arrayWithObjects:mod0, mod1, mod2, mod3, mod4, nil]];
	}
	[ctrl showWindow:sender];
}

-(void)showLeftMenuPaneInPreferencesPanel:(id)sender {
	[self showPreferencesPanel:self];
	
	MBPreferencesController* ctrl = [MBPreferencesController sharedController];
	id<MBPreferencesModule> thing = [ctrl moduleForIdentifier:@"LeftMenuPane"];
		
	if(thing != nil) {
		[ctrl changeToModule:thing animate:NO];
	}
}

-(void)showRightMenuPaneInPreferencesPanel:(id)sender {
	[self showPreferencesPanel:self];
	
	MBPreferencesController* ctrl = [MBPreferencesController sharedController];
	id<MBPreferencesModule> thing = [ctrl moduleForIdentifier:@"RightMenuPane"];
		
	if(thing != nil) {
		[ctrl changeToModule:thing animate:NO];
	}
}

-(void)showBookmarkPaneInPreferencesPanel:(id)sender {
	[self showPreferencesPanel:self];
	
	MBPreferencesController* ctrl = [MBPreferencesController sharedController];
	id<MBPreferencesModule> thing = [ctrl moduleForIdentifier:@"BookmarkPane"];
		
	if(thing != nil) {
		[ctrl changeToModule:thing animate:NO];
	}
}


@end
