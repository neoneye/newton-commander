//
//  NCPanelController.m
//  NewtonCommander
//
//  Created by Simon Strandgaard on 25/01/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "NCLog.h"
#import "NCListPanelController.h"
#import "NCBackground.h"
#import "NCLister.h"
#import "NCPreferencesMenuController.h"
#import "NCGotoFolderController.h"
#import "AppDelegate.h"
#import "NCTabArray.h"     
#import "PSMTabBarControl.h"
#import "PSMTabStyle.h"
#import "NCListPanelTabModel.h"
#import "NCListTabController.h"
#import "NSTabView+SwitchExtensions.h"

@interface NCListPanelController () <PSMTabBarControlDelegate> {
	PSMTabBarControl* __weak m_tabbar;
	NSTabView* __weak m_tabview;
	
	BOOL m_is_left_panel;
}

@property (weak) IBOutlet PSMTabBarControl* tabBar;
@property (weak) IBOutlet NSTabView* tabView;

-(NCListTabController*)currentListTabController;
-(void)loadWithTabArray:(NCTabArray*)tabarray;    

@end

@implementation NCListPanelController

@synthesize delegate = m_delegate;
@synthesize tabBar = m_tabbar;
@synthesize tabView = m_tabview;

-(id)initAsLeftPanel:(BOOL)is_left_panel {
	self = [super initWithNibName:@"ListPanel" bundle:nil];
	if(self) {
		m_is_left_panel = is_left_panel;
	}
    return self;
}

- (void)awakeFromNib {
	[m_tabview setTabViewType:NSNoTabsNoBorder];
	if(0) {
		[m_tabview setTabViewType:NSTopTabsBezelBorder];
	}


	[m_tabbar setDelegate:self];
	
	[m_tabbar setPartnerView:m_tabview];
	[m_tabbar setTabView:m_tabview];


	// mini window looks best IMO
	// [m_tabbar setTearOffStyle:PSMTabBarTearOffAlphaWindow];
	[m_tabbar setTearOffStyle:PSMTabBarTearOffMiniwindow];

	// IDEA: what does scrubbing do ? and is it useful for us?
	// [m_tabbar setAllowsScrubbing:YES];
	// [m_tabbar setAllowsScrubbing:NO];

	// [m_tabbar setAutomaticallyAnimates:NO];
	[m_tabbar setAutomaticallyAnimates:YES];
	
	
	[m_tabbar setSelectsTabsOnMouseDown:YES];

	
	[m_tabbar setDisableTabClose:YES];
	[m_tabbar setShowAddTabButton:NO];


	// remove any tabs present in the nib
	[m_tabview removeAllTabs:self];

	NCTabArray* tabarray = nil;
	if(m_is_left_panel) {
		tabarray = [NCTabArray arrayLeft];
	} else {
		tabarray = [NCTabArray arrayRight];
	}
	[tabarray load];

	if(tabarray) {
		[self loadWithTabArray:tabarray];
	}
	if([m_tabview numberOfTabViewItems] < 1) {
		[self addNewTab:self];
	}
}

- (IBAction)addNewTab:(id)sender {
	NCListPanelTabModel* model = [[NCListPanelTabModel alloc] init];
	NSTabViewItem* item = [[NSTabViewItem alloc] initWithIdentifier:model];

	NCListTabController* lpt = [[NCListTabController alloc] initAsLeftPanel:m_is_left_panel];
	[model setController:lpt];
	[lpt setDelegate:self];
	[lpt setTabModel:model];
	
	NSView* v = [lpt view];
	[item setView:v];

	[m_tabview addTabViewItem:item];
	[m_tabview selectTabViewItem:item]; // this is optional, but expected behavior

	[lpt setNextResponder:self];
}

-(void)loadWithTabArray:(NCTabArray*)tabarray {
	[m_tabview removeAllTabs:self];

	int selected_index = [tabarray selectedIndex];

	// LOG_DEBUG(@"%@", tabarray);
	
	{
		[tabarray firstTab];
		int n = [tabarray numberOfTabs];
		for(int i=0; i<n; i++) {
		
			NSString* wdir = [tabarray workingDir];
		
			// LOG_DEBUG(@"%s %i of %i: %@\n%@", _cmd, i, n, wdir, [tabarray currentItem]);
		
			[self addNewTab:self];
			[self setWorkingDir:wdir];
			// TODO: [self setCurrentName:[tabarray cursorName]];
		
			[tabarray nextTab];
		}
	}
	
	{
		NSInteger n = [m_tabview numberOfTabViewItems];
		if((n > 1) && (selected_index < n)) {
			[m_tabview selectTabViewItemAtIndex:selected_index];
		}
	}
}

-(void)saveTabState {
	NCTabArray* tabarray = nil;
	if(m_is_left_panel) {
		tabarray = [NCTabArray arrayLeft];
	} else {
		tabarray = [NCTabArray arrayRight];
	}

	// remove all tabs, but one.. (however closeTab will not remove the last tab)
	{
		[tabarray firstTab];
		int n = [tabarray numberOfTabs];
		for(int i=0; i<n; i++) {
			[tabarray closeTab];
		}
	}


	// remember the workingdir for all the tab
	{
		int i = 0;
		NSEnumerator* e = [[m_tabview tabViewItems] objectEnumerator];
		NSTabViewItem* item;
		while(item = [e nextObject]) {
			id obj = [item identifier];
			if(![obj respondsToSelector:@selector(controller)]) continue;
			
			NCListTabController* ctrl = [obj controller];
			NSString* wdir = [ctrl workingDir];
			// LOG_DEBUG(@"%s %@", _cmd, wdir);
			
			if(i > 0) {
				[tabarray insertNewTab];
			}
			[tabarray setWorkingDir:wdir]; 
			// TODO: [tabarray setCursorName:cursor];  remember the current selected file
			// TODO: remember the scroll position
			i++;
		}
	}

	// remember the currently active tab
	{
		NSInteger index = 0;
		NSTabViewItem* item = [m_tabview selectedTabViewItem];
		if(item) {
			index = [m_tabview indexOfTabViewItem:item];

			[tabarray firstTab];
			for(int i=0; i<index; i++) {
				[tabarray nextTab];
			}
		}
	}

	[tabarray save];
}

- (BOOL)acceptsFirstResponder {
	return NO;
}

-(void)keyDown:(NSEvent *)theEvent {
	// LOG_DEBUG(@"%@", theEvent);
	[super keyDown:theEvent];
}

-(NCListTabController*)currentListTabController {
	NCListTabController* ctrl = nil;
	id obj = [[m_tabview selectedTabViewItem] identifier];
	if([obj respondsToSelector:@selector(controller)]) ctrl = [obj controller];
	return ctrl;
}

-(IBAction)activatePanel:(id)sender {
	[[self currentListTabController] activate];
}

-(IBAction)deactivatePanel:(id)sender {
	[[self currentListTabController] deactivate];
}

-(void)tabKeyPressed:(id)sender {
	// LOG_DEBUG(@"pressed");
	if([m_delegate respondsToSelector:@selector(tabKeyPressed:)]) {
		[m_delegate tabKeyPressed:self];
	}
}

-(IBAction)selectAllOrNone:(id)sender {
	[[self currentListTabController] selectAllOrNone];
}

-(IBAction)newTab:(id)sender { 
	// LOG_DEBUG(@"new tab");
	NSString* wdir = [self workingDir];
	
	[self saveColumnLayout];
	[[self currentListTabController] deactivate];
	[self addNewTab:self];
	[self setWorkingDir:wdir];
	[self workingDirDidChange:self];
	[self loadColumnLayout];
}

-(void)switchToNextTab:(id)sender {
	[self saveColumnLayout];
	[[self currentListTabController] deactivate];
	[m_tabview selectNextOrFirstTabViewItem:self];
	[self workingDirDidChange:self];
	[self loadColumnLayout];
}

-(void)switchToPrevTab:(id)sender {
	[self saveColumnLayout];
	[[self currentListTabController] deactivate];
	[m_tabview selectPreviousOrLastTabViewItem:self];
	[self workingDirDidChange:self];
	[self loadColumnLayout];
}

-(void)closeTab:(id)sender {
	NSInteger n = [m_tabview numberOfTabViewItems];
	if(n >= 2) {
		[self saveColumnLayout];
		[[self currentListTabController] deactivate];
		[m_tabview removeTabViewItem:[m_tabview selectedTabViewItem]];
		[self workingDirDidChange:self];
		[self loadColumnLayout];
	}
}

-(void)activateTableView:(id)sender {
	if([m_delegate respondsToSelector:@selector(clickToActivatePanel:)]) {
		[m_delegate clickToActivatePanel:self];
	}
}

-(void)workingDirDidChange:(id)sender {
	{
		NSString* label = [[self workingDir] lastPathComponent];
		[[m_tabview selectedTabViewItem] setLabel:label];
	}

	if([m_delegate respondsToSelector:@selector(workingDirDidChange:)]) {
		[m_delegate workingDirDidChange:self];
	}
}

-(NSString*)workingDir {
	return [[self currentListTabController] workingDir];
}

-(void)setWorkingDir:(NSString*)s {
	[[self currentListTabController] setWorkingDir:s];
}

-(NSString*)currentName {
	return [[self currentListTabController] currentName];
}

-(NSArray*)selectedNamesOrCurrentName {
	return [[self currentListTabController] selectedNamesOrCurrentName];
}

-(void)reload {
	[[self currentListTabController] reload];
}

-(void)saveColumnLayout {
	[[self currentListTabController] saveColumnLayout];
}

-(void)loadColumnLayout {
	[[self currentListTabController] loadColumnLayout];
}

-(void)enterRenameMode {
	[[self currentListTabController] enterRenameMode];
}


-(void)showGotoFolderSheet {
	NCGotoFolderController* ctrl = [NCGotoFolderController shared];
	[ctrl setDelegate:self];
	[ctrl beginSheetForWindow:[[self view] window]];
}

/*
TODO: Move this code to the panel controller.. since this code is affecting only 1 panel
*/
-(BOOL)makeGotoFolderController:(NCGotoFolderController*)ctrl gotoFolder:(NSString*)path {
	if([path length] <= 0) {
		// close sheet
		return YES;
	}

	NSString* wdir0 = [self workingDir];

	NSString* result = path;
	if(![result isAbsolutePath]) {
		result = [wdir0 stringByAppendingPathComponent:path];
	}

	[self setWorkingDir:result];
	//NSString* wdir1 = [self workingDir];
	if(NO) {
	// if([wdir0 isEqual:wdir1]) { // TODO: why doesn't this work with the new tab system?
		// don't close sheet, allow the user to change the path again
		return NO;
	}
	return YES;
}

-(void)switchToUser:(int)user_id {
	[[self currentListTabController] switchToUser:user_id];
}

-(id<NCCopyOperationProtocol>)copyOperation {
	return [[self currentListTabController] copyOperation];
}

-(id<NCMoveOperationProtocol>)moveOperation {
	return [[self currentListTabController] moveOperation];
}


#pragma mark -
#pragma mark PSMTabBarControl delegate

- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem {
	[self saveColumnLayout];
}

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
	[[self currentListTabController] activate];
	[self loadColumnLayout];
}

- (BOOL)tabView:(NSTabView *)aTabView shouldCloseTabViewItem:(NSTabViewItem *)tabViewItem {
	return YES;
}

- (void)tabView:(NSTabView *)aTabView didCloseTabViewItem:(NSTabViewItem *)tabViewItem {
	// empty
}

- (NSArray *)allowedDraggedTypesForTabView:(NSTabView *)aTabView {
	return [NSArray arrayWithObjects:NSFilenamesPboardType, NSStringPboardType, nil];
}

- (void)tabView:(NSTabView *)aTabView acceptedDraggingInfo:(id <NSDraggingInfo>)draggingInfo onTabViewItem:(NSTabViewItem *)tabViewItem {
	LOG_DEBUG(@"acceptedDraggingInfo: %@ onTabViewItem: %@", [[draggingInfo draggingPasteboard] stringForType:[[[draggingInfo draggingPasteboard] types] objectAtIndex:0]], [tabViewItem label]);
}

- (NSMenu *)tabView:(NSTabView *)aTabView menuForTabViewItem:(NSTabViewItem *)tabViewItem {
	LOG_DEBUG(@"menuForTabViewItem: %@", [tabViewItem label]);
	/*
	IDEA: what can we put in this context menu ? 
	menu for:  /usr/include/test/xyzdir/
	 1. xyzdir
	 2. test
	 3. include
	 4. usr
	 5. /
	*/
	return nil;
}

- (BOOL)tabView:(NSTabView*)aTabView shouldDragTabViewItem:(NSTabViewItem *)tabViewItem fromTabBar:(PSMTabBarControl *)tabBarControl {
	NSInteger n = [aTabView numberOfTabViewItems];
	return (n >= 2);
}

- (BOOL)tabView:(NSTabView*)aTabView shouldDropTabViewItem:(NSTabViewItem *)tabViewItem inTabBar:(PSMTabBarControl *)tabBarControl {
	return YES;
}

/*
when a TabViewItem is dragged from the left panel and dropped into the right panel, 
then it's necessary to update the delegate and the responder chain and some other info,
otherwise the lister will behave as it still sits in that panel.   

this also transfers the column layout to the dropped tabviewitem
*/
-(void)syncItemsWithController {
	NSEnumerator* e = [[m_tabview tabViewItems] objectEnumerator];
	NSTabViewItem* item;
	while(item = [e nextObject]) {
		id obj = [item identifier];
		if(![obj respondsToSelector:@selector(controller)]) continue;
		
		NCListTabController* ctrl = [obj controller];
		[ctrl setDelegate:self];
		[ctrl setNextResponder:self];
		[ctrl setIsLeftPanel:m_is_left_panel];
		[ctrl loadColumnLayout];
	}
}

/*
there are two kind of dragndrop operations:
 1. when a dragndrop stays within the tabbar then it's simple.
 2. when a dragndrop goes across the panels then a lot of things is happening.
*/
- (void)tabView:(NSTabView*)aTabView didDropTabViewItem:(NSTabViewItem *)tabViewItem inTabBar:(PSMTabBarControl *)tabBarControl {
	// LOG_DEBUG(@"didDropTabViewItem: %@ inTabBar: %@", [tabViewItem label], tabBarControl);
	
	if(tabBarControl == m_tabbar) {
		// LOG_DEBUG(@"%s tabbar matches - dragndrop within the tabbar", _cmd);
		return;
	}

	// LOG_DEBUG(@"dragndrop outside the panel");
	if([m_delegate respondsToSelector:@selector(tabViewItemsDidChange:)]) {
		[m_delegate tabViewItemsDidChange:self];
	}

	// activate the panel and deactivate the other panel
	{
		id obj = [tabViewItem identifier];
		if([obj respondsToSelector:@selector(controller)]) {
			[[aTabView window] makeFirstResponder:nil];
			NCListTabController* ctrl = [obj controller];
			[ctrl activate];
		}
	}
}

- (NSImage *)tabView:(NSTabView *)aTabView imageForTabViewItem:(NSTabViewItem *)tabViewItem offset:(NSSize *)offset styleMask:(NSUInteger *)styleMask {
	id thing = [aTabView delegate];
	if(![thing isKindOfClass:[PSMTabBarControl class]]) return nil;
	PSMTabBarControl* psm_tabbarcontrol = (PSMTabBarControl*)thing;
	id<PSMTabStyle> style = [psm_tabbarcontrol style];
	
	
	// grabs whole window image
	NSWindow* window = [m_tabview window];
	NSImage *viewImage = [[NSImage alloc] init];
	NSRect contentFrame = [[window contentView] frame];
	[[window contentView] lockFocus];
	NSBitmapImageRep *viewRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:contentFrame];
	[viewImage addRepresentation:viewRep];
	[[window contentView] unlockFocus];

	// grabs snapshot of dragged tabViewItem's view (represents content being dragged)
	NSView *viewForImage = [tabViewItem view];
	NSRect viewRect = [viewForImage frame];
	NSImage *tabViewImage = [[NSImage alloc] initWithSize:viewRect.size];
	[tabViewImage lockFocus];
	[viewForImage drawRect:[viewForImage bounds]];
	[tabViewImage unlockFocus];

	[viewImage lockFocus];
	NSPoint tabOrigin = [m_tabview frame].origin;
	tabOrigin.x += 10;
	tabOrigin.y += 13;
	[tabViewImage compositeToPoint:tabOrigin operation:NSCompositeSourceOver];
	[viewImage unlockFocus];

	//draw over where the tab bar would usually be
	NSRect tabFrame = [m_tabbar frame];
	[viewImage lockFocus];
	[[NSColor windowBackgroundColor] set];
	NSRectFill(tabFrame);
	//draw the background flipped, which is actually the right way up
	NSAffineTransform *transform = [NSAffineTransform transform];
	[transform scaleXBy:1.0 yBy:-1.0];
	[transform concat];
	tabFrame.origin.y = -tabFrame.origin.y - tabFrame.size.height;
	[style drawBackgroundInRect:tabFrame];
	[transform invert];
	[transform concat];

	[viewImage unlockFocus];

	if([psm_tabbarcontrol orientation] == PSMTabBarHorizontalOrientation) {
		offset->width = [style leftMarginForTabBarControl];
		offset->height = 22;
	} else {
		offset->width = 0;
		offset->height = 22 + [style leftMarginForTabBarControl];
	}

	if(styleMask) {
		*styleMask = NSTitledWindowMask | NSTexturedBackgroundWindowMask;
	}

	return viewImage;
}

- (PSMTabBarControl *)tabView:(NSTabView *)aTabView newTabBarForDraggedTabViewItem:(NSTabViewItem *)tabViewItem atPoint:(NSPoint)point {
	LOG_DEBUG(@"newTabBarForDraggedTabViewItem: %@ atPoint: %@", [tabViewItem label], NSStringFromPoint(point));
/*
	//create a new window controller with no tab items
	DemoWindowController *controller = [[DemoWindowController alloc] initWithWindowNibName:@"DemoWindow"];
	id <PSMTabStyle> style = (id <PSMTabStyle>)[[aTabView delegate] style];

	NSRect windowFrame = [[controller window] frame];
	point.y += windowFrame.size.height - [[[controller window] contentView] frame].size.height;
	point.x -= [style leftMarginForTabBarControl];

	[[controller window] setFrameTopLeftPoint:point];
	[[controller tabBar] setStyle:style];

	return [controller tabBar]; */
	return nil;
}

- (void)tabView:(NSTabView *)aTabView closeWindowForLastTabViewItem:(NSTabViewItem *)tabViewItem {
	// LOG_DEBUG(@"closeWindowForLastTabViewItem: %@", [tabViewItem label]);
	// do nothing - we don't want to close the window when the last tab is closed
}

- (void)tabView:(NSTabView *)aTabView tabBarDidHide:(PSMTabBarControl *)tabBarControl {
	// LOG_DEBUG(@"tabBarDidHide: %@", tabBarControl);
}

- (void)tabView:(NSTabView *)aTabView tabBarDidUnhide:(PSMTabBarControl *)tabBarControl {
	// LOG_DEBUG(@"tabBarDidUnhide: %@", tabBarControl);
}

- (NSString *)tabView:(NSTabView *)aTabView toolTipForTabViewItem:(NSTabViewItem *)tabViewItem {
	return [tabViewItem label];
}

- (NSString *)accessibilityStringForTabView:(NSTabView *)aTabView objectCount:(NSInteger)objectCount {
	return (objectCount == 1) ? @"item" : @"items";
}


@end
