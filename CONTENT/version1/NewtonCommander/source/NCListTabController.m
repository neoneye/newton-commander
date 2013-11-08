//
//  NCListPanelTab.m
//  NewtonCommander
//
//  Created by Simon Strandgaard on 27/06/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import "NCLog.h"                                                  
#import "NCListTabController.h"
#import "NCLister.h"
#import "NCTabArray.h"     
#import "AppDelegate.h"
#import "NCPreferencesMenuController.h"
#import "NCListPanelModel.h"
#import "NCListerDataSourceAdvanced.h"
#import "NCPathControl.h"
#import "NCVolumeStatus.h"
#import "NCListPanelTabModel.h"
#import "NCListerCounter.h"
#import "VerticalLayoutView.h"

// #define WITHOUT_IBPLUGINS
#define WITH_IBPLUGINS

@interface NCListTabController (Private)
-(NSMenu*)buildMenuWithItems:(NSArray*)items customizeMenuTag:(int)customize_menu_tag;
-(void)updateVolumeStatus;
@end

@implementation NCListTabController

@synthesize delegate = m_delegate;
@synthesize lister = m_lister;
@synthesize listerCounter = m_lister_counter;
// @synthesize background = m_background;
@synthesize pathControl = m_path_control;
@synthesize volumeStatus = m_volume_status;
@synthesize model = m_model;
@synthesize modelController = m_model_controller;
@synthesize dataSource = m_data_source;
@synthesize tabModel = m_tab_model;

- (id)initAsLeftPanel:(BOOL)is_left_panel {
#ifdef WITHOUT_IBPLUGINS
	self = [super initWithNibName:nil bundle:nil];
    if (self) {
		m_is_left_panel = is_left_panel;

		NCListPanelModel* m = [[[NCListPanelModel alloc] init] autorelease];
		// [m setWorkingDir:path];  
		[self setModel:m];
		
		VerticalLayoutView* layout = [[[VerticalLayoutView alloc] initWithFrame:NSMakeRect(0, 0, 500, 500)] autorelease];
		{
			NCPathControl* view = [[[NCPathControl alloc] initWithFrame:NSMakeRect(0, 0, 400, 50)] autorelease];
			[layout addSubview:view];
			[layout setHeight:21 forIndex:0];
			self.pathControl = view;
		}
/*		{
			NSRect          scrollFrame = NSMakeRect( 10, 10, 300, 300 );
		    NSScrollView*   scrollView  = [[[NSScrollView alloc] initWithFrame:scrollFrame] autorelease];

		    [scrollView setHasVerticalScroller:YES];
		    [scrollView setHasHorizontalScroller:YES];
		    [scrollView setAutohidesScrollers:NO];

		    NSRect          clipViewBounds  = [[scrollView contentView] bounds];
		    NSTableView*    tableView       = [[[NSTableView alloc] initWithFrame:clipViewBounds] autorelease];

		    NSTableColumn*  firstColumn     = [[[NSTableColumn alloc] initWithIdentifier:@"firstColumn"] autorelease];
		    [[firstColumn headerCell] setStringValue:@"First Column"];
		    [tableView  addTableColumn:firstColumn];

		    NSTableColumn*  secondColumn        = [[[NSTableColumn alloc] initWithIdentifier:@"secondColumn"] autorelease];
		    [[secondColumn headerCell] setStringValue:@"Second Column"];
		    [tableView  addTableColumn:secondColumn];

		    [tableView setDataSource:self];
		    [scrollView setDocumentView:tableView];

		    [layout addSubview:scrollView];
			[layout setHeight:300 forIndex:1];
			[layout setFlexibleView:scrollView];
		}*/
		{
			NCLister* view = [[[NCLister alloc] initWithFrame:NSMakeRect(0, 100, 400, 300)] autorelease];
			[layout addSubview:view];
			[layout setHeight:300 forIndex:1];
			[layout setFlexibleView:view];
			// view.delegate = self;
			self.lister = view;
		}/**/
		{
			NCListerCounter* view = [[[NCListerCounter alloc] initWithFrame:NSMakeRect(0, 400, 400, 50)] autorelease];
			[layout addSubview:view];
			[layout setHeight:25 forIndex:1];
			[layout setHeight:25 forIndex:2];
			self.listerCounter = view;
		}
		[self setView:layout];
		
		// self.modelController = [NSObjectController alloc]
		
		[self awakeFromNib];
    }
    return self;
#endif
#ifdef WITH_IBPLUGINS
	self = [super initWithNibName:@"ListPanelTab" bundle:nil];
    if (self) {
		m_is_left_panel = is_left_panel;

		NCListPanelModel* m = [[[NCListPanelModel alloc] init] autorelease];
		// [m setWorkingDir:path];  
		[self setModel:m];
    }
    return self;
#endif
}

- (void)awakeFromNib {

	NSAssert(m_model_controller, @"must be initialized by nib");
	NSAssert(m_lister_counter, @"must be initialized by nib");

	NCListerDataSourceAdvanced* data_source = [[[NCListerDataSourceAdvanced alloc] init] autorelease];
	[m_lister setDataSource:data_source];
	[self setDataSource:data_source];
	
	
	// [m_path_control setDelegate:self];
    [m_path_control setTarget:self];
    [m_path_control setAction:@selector(pathControlAction:)];
	
	
	[m_volume_status setCapacity:75000];
	[m_volume_status setAvailable:1000];

    [m_model addObserver:self
             forKeyPath:@"workingDir"
                 options:NSKeyValueObservingOptionNew
                    context:NULL];


	[m_lister_counter bind: @"numberOfDirs" toObject: m_model_controller
		   withKeyPath:@"selection.numberOfDirs" options:nil];
	[m_lister_counter bind: @"numberOfFiles" toObject: m_model_controller
		   withKeyPath:@"selection.numberOfFiles" options:nil];
	[m_lister_counter bind: @"sizeOfItems" toObject: m_model_controller
		   withKeyPath:@"selection.sizeOfItems" options:nil];
	[m_lister_counter bind: @"numberOfSelectedDirs" toObject: m_model_controller
		   withKeyPath:@"selection.numberOfSelectedDirs" options:nil];
	[m_lister_counter bind: @"numberOfSelectedFiles" toObject: m_model_controller
		   withKeyPath:@"selection.numberOfSelectedFiles" options:nil];
	[m_lister_counter bind: @"sizeOfSelectedItems" toObject: m_model_controller
		   withKeyPath:@"selection.sizeOfSelectedItems" options:nil];


	[m_lister setDelegate:self];
	[m_lister setNextResponder:self];
	
	NSString* name = m_is_left_panel ? @"left" : @"right";
	[m_lister setAutoSaveName:name];

	[m_lister loadColumnLayout];
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

- (void)observeValueForKeyPath:(NSString *)keyPath
              ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
	// LOG_DEBUG(@"keypath: %@", keyPath);
    if ([keyPath isEqual:@"workingDir"]) {
		id value = [change objectForKey:NSKeyValueChangeNewKey];
		// LOG_DEBUG(@"workingDir did change: %@", value);
		
		if([value isKindOfClass:[NSString class]]) {
			NSString* working_dir = (NSString*)value;

			[m_path_control setPath:working_dir];

			[self updateVolumeStatus];
			
		
/*			NSFileManager* fm = [NSFileManager defaultManager];
			NSDictionary* dict = [fm attributesOfFileSystemForPath:path error:NULL];
			LOG_DEBUG(@"dict: %@", dict);*/

			SEL sel = @selector(workingDirDidChange:);
			if([m_delegate respondsToSelector:sel]) {
				[m_delegate performSelector:sel withObject:self];
			}

		}
		
		return;
    }
    // be sure to call the super implementation
    // if the superclass implements it
    [super observeValueForKeyPath:keyPath
                ofObject:object
                 change:change
                 context:context];
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

-(void)tabKeyPressed:(id)sender {
	SEL sel = @selector(tabKeyPressed:);
	if([m_delegate respondsToSelector:sel]) {
		[m_delegate performSelector:sel withObject:self];
	}
}

-(void)switchToNextTab:(id)sender {
	SEL sel = @selector(switchToNextTab:);
	if([m_delegate respondsToSelector:sel]) {
		[m_delegate performSelector:sel withObject:self];
	}
}

-(void)listerWillLoad:(id)sender {
	if(m_tab_model) {
		[m_tab_model setIsProcessing:YES];
	}
}

-(void)listerDidLoad:(id)sender {
	if(m_tab_model) {
		[m_tab_model setIsProcessing:NO];
	}
}

-(void)switchToPrevTab:(id)sender {
	SEL sel = @selector(switchToPrevTab:);
	if([m_delegate respondsToSelector:sel]) {
		[m_delegate performSelector:sel withObject:self];
	}
}

-(void)closeTab:(id)sender {
	SEL sel = @selector(closeTab:);
	if([m_delegate respondsToSelector:sel]) {
		[m_delegate performSelector:sel withObject:self];
	}
}

-(void)activateTableView:(id)sender {
	SEL sel = @selector(activateTableView:);
	if([m_delegate respondsToSelector:sel]) {
		[m_delegate performSelector:sel withObject:self];
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

-(NSMenu*)leftMenu {
	NSArray* items = [NCPreferencesLeftMenuController loadDefaultItems];
	return [self buildMenuWithItems:items customizeMenuTag:500];
}

-(NSMenu*)rightMenu {
	NSArray* items = [NCPreferencesRightMenuController loadDefaultItems];
	return [self buildMenuWithItems:items customizeMenuTag:501];
}

-(NSMenu*)buildMenuWithItems:(NSArray*)items customizeMenuTag:(int)customize_menu_tag {
	NSMenu* menu = [[[NSMenu alloc] initWithTitle:@"Menu"] autorelease];

	// build menu items from whats stored in user defaults
	id thing;
	NSEnumerator* e = [items objectEnumerator];
	while(thing = [e nextObject]) {
		if([thing isKindOfClass:[NCUserDefaultMenuItem class]] == NO) continue;
		NCUserDefaultMenuItem* ami = (NCUserDefaultMenuItem*)thing;

		NSMenuItem* mi = [[[NSMenuItem alloc] 
			initWithTitle:[ami name]
			action:@selector(contextMenuAction:) 
			keyEquivalent:@""] autorelease];
		[mi setTag:1];
		[mi setRepresentedObject:ami];
		[mi setTarget:self];
		[menu addItem:mi];
	}

	[menu addItem:[NSMenuItem separatorItem]];
	{
		NSMenuItem* mi = [[[NSMenuItem alloc] 
			initWithTitle:@"Customize…" 
			action:@selector(contextMenuAction:) 
			keyEquivalent:@""] autorelease];
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
