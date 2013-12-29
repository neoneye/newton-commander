//
//  NCListTabController.m
//  Newton Commander
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "NCLog.h"                                                  
#import "NCListTabController.h"
#import "NCTabArray.h"     
#import "AppDelegate.h"
#import "NCPreferencesMenuController.h"
#import "NCListerDataSourceAdvanced.h"
#import "NCPathControl.h"
#import "NCVolumeStatus.h"
#import "NCListPanelTabModel.h"
#import "NCListerCounter.h"
#import "VerticalLayoutView.h"



@interface NCListTabController ()
-(NSMenu*)buildMenuWithItems:(NSArray*)items customizeMenuTag:(int)customize_menu_tag;
-(void)updateVolumeStatus;
-(void)workingDirDidChange;
@end

@implementation NCListTabController

@synthesize lister = m_lister;
@synthesize listerCounter = m_lister_counter;
// @synthesize background = m_background;
@synthesize pathControl = m_path_control;
@synthesize volumeStatus = m_volume_status;
@synthesize dataSource = m_data_source;
@synthesize tabModel = m_tab_model;

- (id)initAsLeftPanel:(BOOL)is_left_panel {
	self = [super initWithNibName:@"ListPanelTab" bundle:nil];
    if (self) {
		m_is_left_panel = is_left_panel;
    }
    return self;
}

- (void)awakeFromNib {

	NSAssert(m_lister_counter, @"must be initialized by nib");

	NCListerDataSourceAdvanced* data_source = [[NCListerDataSourceAdvanced alloc] initWithWorkerPath:[AppDelegate pathToWorker]];
	[m_lister setDataSource:data_source];
	[self setDataSource:data_source];
	
	
	// [m_path_control setDelegate:self];
    [m_path_control setTarget:self];
    [m_path_control setAction:@selector(pathControlAction:)];
	
	
	[m_volume_status setCapacity:75000];
	[m_volume_status setAvailable:1000];


	[m_lister setDelegate:self];
	[m_lister setNextResponder:self];

	[m_lister setWorkingDir:@"/"];
	
	NSString* name = m_is_left_panel ? @"left" : @"right";
	[m_lister setAutoSaveName:name];

	[m_lister loadColumnLayout];
}

-(void)listerDidUpdateCounters:(NCLister*)aLister {
	// LOG_DEBUG(@"counters");
	
	NCListerCountersStruct counters = aLister.counters;
	
	m_lister_counter.numberOfDirs = counters.number_of_directories;
	m_lister_counter.numberOfSelectedDirs = counters.number_of_selected_directories;
	
	m_lister_counter.numberOfFiles = counters.number_of_files;
	m_lister_counter.numberOfSelectedFiles = counters.number_of_selected_files;
	
	m_lister_counter.sizeOfItems = counters.size_of_items;
	m_lister_counter.sizeOfSelectedItems = counters.size_of_selected_items;
}


-(void)setIsLeftPanel:(BOOL)is_left_panel {
	m_is_left_panel = is_left_panel;
	
	NSString* name = m_is_left_panel ? @"left" : @"right";
	[m_lister setAutoSaveName:name];
}

-(void)pathControlAction:(id)sender {
	// int tag = [sender tag];
	NSPathComponentCell* cell = [m_path_control clickedPathComponentCell];
	// LOG_DEBUG(@"tag: %i", tag);
	NSURL* url = [cell URL];
	NSString* path = [url path];
	// LOG_DEBUG(@"path: %@", path);
	if(path) {
		[self setWorkingDir:path];
	}
}

-(void)listerDidResolveWorkingDirectory:(NCLister*)aLister {
	// LOG_DEBUG(@"did resolve working directory");
	[self workingDirDidChange];
}


-(void)listerDidChangeWorkingDirectory:(NCLister*)aLister {
	// LOG_DEBUG(@"did change working directory");
	// [self workingDirDidChange];  // maybe do this.. maybe not
}

-(void)updateVolumeStatus {
	NSString* wdir = [self workingDir];
	if(!wdir) {
		return;
	}

	/*
	TODO: obtain this info via the worker process
	*/
	NSFileManager* fm = [NSFileManager defaultManager];
	NSDictionary* dict = [fm attributesOfFileSystemForPath:wdir error:NULL];
	if(dict == nil) {
		return;
	}

	NSNumber* fs_capacity1 = [dict objectForKey:NSFileSystemSize];
	NSNumber* fs_avail1    = [dict objectForKey:NSFileSystemFreeSize];
	
	long long fs_capacity = 0;
	long long fs_avail = 0;
	
	if(fs_capacity1 != nil) {
		fs_capacity = [fs_capacity1 longLongValue];
	}
	if(fs_avail1 != nil) {
		fs_avail = [fs_avail1 longLongValue];
	}

	[m_volume_status setCapacity:fs_capacity];
	[m_volume_status setAvailable:fs_avail];
}

-(void)listerWillLoad:(NCLister*)aLister {
	if(m_tab_model) {
		[m_tab_model setIsProcessing:YES];
	}
	// LOG_DEBUG(@"lister will load");
	
	[self workingDirDidChange];
}

-(void)listerDidLoad:(NCLister*)aLister {
	if(m_tab_model) {
		[m_tab_model setIsProcessing:NO];
	}
}

-(void)listerTabKeyPressed:(NCLister*)aLister {
	if([self.delegate respondsToSelector:@selector(tabKeyPressed:)]) {
		[self.delegate tabKeyPressed:self];
	}
}

-(void)listerSwitchToNextTab:(NCLister*)aLister {
	if([self.delegate respondsToSelector:@selector(switchToNextTab:)]) {
		[self.delegate switchToNextTab:self];
	}
}

-(void)listerSwitchToPrevTab:(NCLister*)aLister {
	if([self.delegate respondsToSelector:@selector(switchToPrevTab:)]) {
		[self.delegate switchToPrevTab:self];
	}
}

-(void)listerCloseTab:(NCLister*)aLister {
	if([self.delegate respondsToSelector:@selector(closeTab:)]) {
		[self.delegate closeTab:self];
	}
}

-(void)listerActivateTableView:(NCLister*)aLister {
	if([self.delegate respondsToSelector:@selector(activateTableView:)]) {
		[self.delegate activateTableView:self];
	}
}

-(void)activate {
	// [m_background setIsActive:YES];
	// [m_background setNeedsDisplay:YES];
	[m_lister activate];
	[m_path_control activate];
	[m_volume_status activate];
}

-(void)deactivate {
	// [m_background setIsActive:NO];
	// [m_background setNeedsDisplay:YES];
	[m_lister deactivate];
	[m_path_control deactivate];
	[m_volume_status deactivate];
}

-(NSString*)workingDir {
	return [m_lister workingDir];
}

-(void)setWorkingDir:(NSString*)s {
	[m_lister navigateToDir:s];
}

-(void)workingDirDidChange {
	NSString* working_dir = [m_lister workingDir];

	[m_path_control setPath:working_dir];

	[self updateVolumeStatus];

	if([self.delegate respondsToSelector:@selector(workingDirDidChange:)]) {
		[self.delegate workingDirDidChange:self];
	}
}

-(NSString*)currentName {
	return [m_lister currentName];
}

-(NSArray*)selectedNamesOrCurrentName {
	return [m_lister selectedNamesOrCurrentName];
}

-(void)reload {
	[m_lister reloadAction:self];
}

-(void)saveColumnLayout {
	[m_lister saveColumnLayout];
}

-(void)loadColumnLayout {
	[m_lister loadColumnLayout];
}

-(void)enterRenameMode {
	[m_lister enterRenameMode];
}

-(void)contextMenuAction:(id)sender {
	id thing = [sender representedObject];
	int tag = [sender tag];
	if(tag == 1) {
		if([thing isKindOfClass:[NCUserDefaultMenuItem class]] == NO) return;
		NCUserDefaultMenuItem* ami = (NCUserDefaultMenuItem*)thing;
		NSString* app_path = [ami path];
		NSDictionary* dict = [[NSBundle bundleWithPath:app_path] infoDictionary];
		if(!dict) {
			LOG_WARNING(@"found no Info.plist within app bundle: %@", app_path);
			return;
		}
		NSString* bundle_identifier = [dict objectForKey:@"CFBundleIdentifier"];
		NSArray* url_array = [m_lister urlArrayWithSelectedItemsOrCurrentItem];
		BOOL ok = [[NSWorkspace sharedWorkspace]
			openURLs:url_array
		    withAppBundleIdentifier:bundle_identifier
			options:NSWorkspaceLaunchDefault
			additionalEventParamDescriptor:nil
			launchIdentifiers:nil
		];
		if(!ok)  {
			LOG_WARNING(@"failed opening files: %@, bundle_identifier: %@", url_array, bundle_identifier);
		}
		return;
	}
	if(tag == 500) {
		[[NSApp delegate] showLeftMenuPaneInPreferencesPanel:self];
		return;
	}
	if(tag == 501) {
		[[NSApp delegate] showRightMenuPaneInPreferencesPanel:self];
		return;
	}
}

-(NSMenu*)listerLeftMenu:(NCLister*)aLister {
	NSArray* items = [NCPreferencesLeftMenuController loadDefaultItems];
	return [self buildMenuWithItems:items customizeMenuTag:500];
}

-(NSMenu*)listerRightMenu:(NCLister*)aLister {
	NSArray* items = [NCPreferencesRightMenuController loadDefaultItems];
	return [self buildMenuWithItems:items customizeMenuTag:501];
}

-(NSMenu*)buildMenuWithItems:(NSArray*)items customizeMenuTag:(int)customize_menu_tag {
	NSMenu* menu = [[NSMenu alloc] initWithTitle:@"Menu"];

	// build menu items from whats stored in user defaults
	id thing;
	NSEnumerator* e = [items objectEnumerator];
	while(thing = [e nextObject]) {
		if([thing isKindOfClass:[NCUserDefaultMenuItem class]] == NO) continue;
		NCUserDefaultMenuItem* ami = (NCUserDefaultMenuItem*)thing;

		NSMenuItem* mi = [[NSMenuItem alloc] 
			initWithTitle:[ami name]
			action:@selector(contextMenuAction:) 
			keyEquivalent:@""];
		[mi setTag:1];
		[mi setRepresentedObject:ami];
		[mi setTarget:self];
		[menu addItem:mi];
	}

	[menu addItem:[NSMenuItem separatorItem]];
	{
		NSMenuItem* mi = [[NSMenuItem alloc] 
			initWithTitle:@"Customize…" 
			action:@selector(contextMenuAction:) 
			keyEquivalent:@""];
		[mi setTag:customize_menu_tag];
		[mi setTarget:self];
		[menu addItem:mi];
	}
	
	return menu;
}

/*
TODO: try move this to the lister class. It's wrong to have it here
*/
-(void)selectAllOrNone {
	if([m_lister editName]) {
		/*
		PROBLEM: rename with CMD A causes all items in the lister to be selected, 
		rather than selecting the text. Hmm, what is wrong?
		SOLUTION: hackish.. by sending selectAll to the first responder we 
		avoid this problem. However I really should investigate the 
		responder chain, how it works, so that it doesn't have to be this ugly.
		*/
		NSResponder* fr = [[m_lister window] firstResponder];
		[fr selectAll:self];
	} else {
		[m_lister nc_selectAllOrNone];
	}
}

-(void)switchToUser:(int)user_id {
	// LOG_DEBUG(@"switch to user id: %i", user_id);
	[m_data_source switchToUser:user_id];
}

-(id<NCCopyOperationProtocol>)copyOperation {
	return [m_data_source copyOperation];
}

-(id<NCMoveOperationProtocol>)moveOperation {
	return [m_data_source moveOperation];
}

@end
