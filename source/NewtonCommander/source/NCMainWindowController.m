//
//  NCMainWindowController.m
//  Newton Commander
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "NCLog.h"
#import "NCMainWindowController.h"
#import "NCMainWindow.h"
#import "NCListPanelController.h"     
#import "NCHelpPanelController.h"     
#import "NCInfoPanelController.h"     
#import "NCViewPanelController.h"     
#import "NCDualPane.h"
#import "NCDualPaneState.h"
#import "NCDualPaneStateList.h"
#import "NCToolbar.h"
// #import "NCBackground.h"
#import "NCCommon.h"
#import "NCLister.h"
#import "MAAttachedWindow.h"
#import "NCSplitView.h"
#import "NSGradient+PredefinedGradients.h"
#import "NSView+SubviewExtensions.h"
#import "NCCopySheet.h"
#import "NCMoveSheet.h"
#import "NCMakeDirController.h"
#import "NCMakeFileController.h"
#import "NCMakeLinkController.h"
#import "NCPermissionSheet.h"
#import "NCDeleteSheet.h"
#import "NCCopyOperationProtocol.h"
#import "NSArray+PrependPath.h"
#import <objc/runtime.h>
#import <ScriptingBridge/ScriptingBridge.h>
#import "Terminal.h"


//#define CUSTOM_WINDOW_BACKGROUND

#define isDrawingCustomFrame YES


@interface NSObject (NSWindowFlagsChangeDelegate)

-(void)flagsChangedInWindow:(NSWindow*)window;

@end


@interface NCMainWindowController () <NCToolbarDelegate, NCPanelControllerDelegate> {
	NCListPanelController* m_list_panel_controller_left;
	NCListPanelController* m_list_panel_controller_right;
	NCHelpPanelController* m_help_panel_controller_left;
	NCHelpPanelController* m_help_panel_controller_right;
	NCInfoPanelController* m_info_panel_controller_left;
	NCInfoPanelController* m_info_panel_controller_right;
	NCViewPanelController* m_view_panel_controller_left;
	NCViewPanelController* m_view_panel_controller_right;
	
	NCDualPane* m_dualpane;
	
	NCToolbar* m_toolbar;
}

@property(strong) NSSplitView* splitView;
@property(strong) NSView* leftView;
@property(strong) NSView* rightView;


-(void)replaceLeftView:(NSView*)view;
-(void)replaceRightView:(NSView*)view;

-(void)refreshWindowTitle;

#ifdef CUSTOM_WINDOW_BACKGROUND
- (float)roundedCornerRadius;
- (void)drawRectOriginal:(NSRect)rect;
#endif

-(NCListPanelController*)activePanel;
-(NCListPanelController*)otherPanel;

@end

@implementation NCMainWindowController

@synthesize dualPane = m_dualpane;
@synthesize toolbar = m_toolbar;
@synthesize listPanelControllerLeft = m_list_panel_controller_left;
@synthesize listPanelControllerRight = m_list_panel_controller_right;

+ (NCMainWindowController*)mainWindowController {
	return [[NCMainWindowController alloc] initWithWindowNibName:@"MainWindow"];
}

- (id)initWithWindowNibName:(NSString *)windowNibName {
	self = [super initWithWindowNibName:windowNibName];
    if(self) {

		
    }
    return self;
}

-(void)windowDidLoad {
	
	// [[self window] setContentBorderThickness: -1 forEdge: NSMaxYEdge];

	[[self window] setFrameAutosaveName: @"MainWindow"];
	// [[self window] setMovableByWindowBackground:YES];
	// [[self window] setMovable:YES];

	// black divider in splitview
	if(1) {
		NSWindow* w = [self window];
		NSView* v = [w contentView];
		NSRect frame = [v frame];
		NCSplitView* sv = [[NCSplitView alloc] initWithFrame:frame];
		[sv setVertical:YES];
		[sv setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
		
		NSRect rect_l, rect_r;
		NSDivideRect(frame, &rect_l, &rect_r, NSWidth(frame) * 0.5, NSMinXEdge);
		NSView* view_l = [[NSView alloc] initWithFrame:rect_l];
		[sv addSubview:view_l];
		NSView* view_r = [[NSView alloc] initWithFrame:rect_r];
		[sv addSubview:view_r];
		[sv adjustSubviews];
		
		[sv setPosition:NSWidth(rect_l) ofDividerAtIndex:0];
		[v addSubview:sv];
		
		self.leftView = view_l;
		self.rightView = view_r;
		self.splitView = sv;
	}

#ifdef CUSTOM_WINDOW_BACKGROUND
	// draw a custom window background
	if(0) {
		/*
		IDEA: figure out how to only show the gradient background for certain windows
		IDEA: figure out how to draw the window title in white?
		*/
		
		NSWindow* window = [self window];
		// LOG_DEBUG(@"done %@", window);


		// Get window's frame view class
		id class = [[[window contentView] superview] class];
		// LOG_DEBUG(@"class=%@", class);


		// Exchange draw rect
		Method m0 = class_getInstanceMethod([self class], @selector(drawRect:));
		class_addMethod(class, @selector(drawRectOriginal:), method_getImplementation(m0), method_getTypeEncoding(m0));
		Method m1 = class_getInstanceMethod(class, @selector(drawRect:));
		Method m2 = class_getInstanceMethod(class, @selector(drawRectOriginal:));
		method_exchangeImplementations(m1, m2);
	}
#endif // CUSTOM_WINDOW_BACKGROUND
    
    // show a toggle fullscreen mode icon in the top/right corner of the window
    [[self window] setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];

	m_dualpane = [[NCDualPane alloc] init];
	[m_dualpane setWindowController:self];
	[m_dualpane setup];
	[m_dualpane setNextResponderForLeftAndRightStates:self];


	{
		NCListPanelController* c = [[NCListPanelController alloc] initAsLeftPanel:YES];
		m_list_panel_controller_left = c;
		[c setDelegate:self];
		[c setNextResponder:m_dualpane];
	}
	{
		NCListPanelController* c = [[NCListPanelController alloc] initAsLeftPanel:NO];
		m_list_panel_controller_right = c;
		[c setDelegate:self];
		[c setNextResponder:m_dualpane];
	}
	{
		NCHelpPanelController* c =
			[[NCHelpPanelController alloc] initWithNibName:@"HelpPanel" bundle:nil];
		m_help_panel_controller_left = c;
		// [c setDelegate:self];
		[c setNextResponder:m_dualpane];
	}
	{
		NCHelpPanelController* c =
			[[NCHelpPanelController alloc] initWithNibName:@"HelpPanel" bundle:nil];
		m_help_panel_controller_right = c;
		// [c setDelegate:self];
		[c setNextResponder:m_dualpane];
	}
	{
		NCInfoPanelController* c =
			[[NCInfoPanelController alloc] initWithNibName:@"InfoPanel" bundle:nil];
		m_info_panel_controller_left = c;
		// [c setDelegate:self];
		[c setNextResponder:m_dualpane];
	}
	{
		NCInfoPanelController* c =
			[[NCInfoPanelController alloc] initWithNibName:@"InfoPanel" bundle:nil];
		m_info_panel_controller_right = c;
		// [c setDelegate:self];
		[c setNextResponder:m_dualpane];
	}
	{
		NCViewPanelController* c =
			[[NCViewPanelController alloc] initWithNibName:@"ViewPanel" bundle:nil];
		m_view_panel_controller_left = c;
		// [c setDelegate:self];
		[c setNextResponder:m_dualpane];
	}
	{
		NCViewPanelController* c =
			[[NCViewPanelController alloc] initWithNibName:@"ViewPanel" bundle:nil];
		m_view_panel_controller_right = c;
		// [c setDelegate:self];
		[c setNextResponder:m_dualpane];
	}

	LOG_DEBUG(@"initializing left panel controller");
	{
		NSViewController* c = m_list_panel_controller_left;
		[self replaceLeftView:[c view]];
	}
	LOG_DEBUG(@"initializing right panel controller");
	{
		NSViewController* c = m_list_panel_controller_right;
		[self replaceRightView:[c view]];
	}
	LOG_DEBUG(@"done initializing panel controllers");
	
	{
		NCToolbar* toolbar = [[NCToolbar alloc] init];
		[toolbar setDelegate:self];
		[toolbar attachToWindow:[self window]];
		[self setToolbar:toolbar];
	}


	[m_dualpane changeState:[m_dualpane stateLeftList]];
	[m_dualpane loadState]; // restores whether left-panel or right-panel was active

	// [self refreshVolumeInfo];
	// [self refreshWindowTitle];


	// LOG_DEBUG(@"leave: left-side, path: %@", [m_list_panel_controller_left workingDir]);
	// LOG_DEBUG(@"leave: right-side, path: %@", [m_list_panel_controller_right workingDir]);
}

-(void)refreshWindowTitle {
	NSString* wdir = [self activeWorkingDir];
	NSString* title = wdir ? wdir : @"Newton Commander";
	[[self window] setTitle:title]; 
}

-(void)volumeUsageAction:(id)sender {
	LOG_DEBUG(@"IDEA: show volume info HUD window when the user clicks the disk-usage control");
}

-(void)replaceLeftView:(NSView*)view {
	[self.leftView replaceSubviewsWithView:view];
}

-(void)replaceRightView:(NSView*)view {
	[self.rightView replaceSubviewsWithView:view];
}

- (BOOL)acceptsFirstResponder {
	return NO;
}

- (void)keyDown:(NSEvent *)theEvent {
	// LOG_DEBUG(@"%@", theEvent);
	[super keyDown:theEvent];
}

-(void)stateDidChange:(NCDualPaneState*)state 
         oldResponder:(NSResponder*)resp 
             oldState:(NCDualPaneState*)state_old 
{
	// [self refreshVolumeInfo];
	// [self refreshWindowTitle];

	NSViewController* l = m_list_panel_controller_left;
	NSViewController* r = m_list_panel_controller_right;
	
	if(state == (NCDualPaneState*)[m_dualpane stateLeftView]) {
		r =  m_view_panel_controller_right;
		[self replaceLeftView: [l view]];
		[self replaceRightView:[r view]];
		[m_list_panel_controller_left activatePanel:self];
		return;
	}

	if(state == (NCDualPaneState*)[m_dualpane stateRightView]) {
		l =  m_view_panel_controller_left;
		[self replaceLeftView: [l view]];
		[self replaceRightView:[r view]];
		[m_list_panel_controller_right activatePanel:self];
		return;
	}

	if(state == (NCDualPaneState*)[m_dualpane stateLeftHelp]) {
		r =  m_help_panel_controller_right;
		[self replaceLeftView: [l view]];
		[self replaceRightView:[r view]];
		[m_list_panel_controller_left activatePanel:self];
		// [m_help_panel_controller_right gatherInfo:m_list_panel_controller_left];
		return;
	}

	if(state == (NCDualPaneState*)[m_dualpane stateRightHelp]) {
		l =  m_help_panel_controller_left;
		[self replaceLeftView: [l view]];
		[self replaceRightView:[r view]];
		[m_list_panel_controller_right activatePanel:self];
		// [m_help_panel_controller_left gatherInfo:m_list_panel_controller_right];
		return;
	}

	if(state == (NCDualPaneState*)[m_dualpane stateLeftInfo]) {
		r =  m_info_panel_controller_right;
		[self replaceLeftView: [l view]];
		[self replaceRightView:[r view]];
		[m_list_panel_controller_left activatePanel:self];
		return;
	}

	if(state == (NCDualPaneState*)[m_dualpane stateRightInfo]) {
		l =  m_info_panel_controller_left;
		[self replaceLeftView: [l view]];
		[self replaceRightView:[r view]];
		[m_list_panel_controller_right activatePanel:self];
		return;
	}

	if(state == (NCDualPaneState*)[m_dualpane stateLeftList]) {
		[self replaceLeftView: [l view]];
		[self replaceRightView:[r view]];

		[m_list_panel_controller_left deactivatePanel:self];
		[m_list_panel_controller_right deactivatePanel:self];

		[m_list_panel_controller_left activatePanel:self];
		return;
	}

	if(state == (NCDualPaneState*)[m_dualpane stateRightList]) {
		[self replaceLeftView: [l view]];
		[self replaceRightView:[r view]];

		[m_list_panel_controller_left deactivatePanel:self];
		[m_list_panel_controller_right deactivatePanel:self];

		[m_list_panel_controller_right activatePanel:self];
		return;
	}
}

-(void)tabKeyPressed:(id)sender {
	// LOG_DEBUG(@"tab to next panel");
	[m_dualpane tabKeyPressed:sender];
}

-(void)clickToActivatePanel:(id)sender {
	// [m_dualpane clickToActivateSide:side];

	NCDualPaneState* state = [m_dualpane state];
	if(sender == m_list_panel_controller_left) {
		if(state == (NCDualPaneState*)[m_dualpane stateRightList]) {
			[m_dualpane changeState:[m_dualpane stateLeftList]];
			return;
		}
	}
	if(sender == m_list_panel_controller_right) {
		if(state == (NCDualPaneState*)[m_dualpane stateLeftList]) {
			[m_dualpane changeState:[m_dualpane stateRightList]];
			return;
		}
	}
}

-(void)fullReload {
	[m_list_panel_controller_left reload];
	[m_list_panel_controller_right reload];
}

-(NSString*)activeWorkingDir {
	return [[self activePanel] workingDir];
}

-(void)setActiveWorkingDir:(NSString*)wdir {
	[[self activePanel] setWorkingDir:wdir];
}


-(void)workingDirDidChange:(id)sender {
	// [self refreshWindowTitle];
	// [self refreshVolumeInfo];
}

-(void)tabViewItemsDidChange:(id)sender {
	[m_list_panel_controller_left syncItemsWithController];
	[m_list_panel_controller_right syncItemsWithController];
}

#if 0
-(void)yswitchToNextTab:(id)sender {
	// LOG_DEBUG(@"MainWindowController %s", _cmd);

#ifdef USE_OLD_TAB_CODE


	[self saveSnapshot];
	int n = [m_snapshot_array count];


	BOOL show_in_left_side = NO;
	BOOL show_in_right_side = NO;
	NCDualPaneState* state = [m_dualpane state];
	if(state == [m_dualpane stateLeftList]) show_in_left_side = YES;
	if(state == [m_dualpane stateLeftInfo]) show_in_left_side = YES;
	if(state == [m_dualpane stateLeftView]) show_in_left_side = YES;
	if(state == [m_dualpane stateRightList]) show_in_right_side = YES;
	if(state == [m_dualpane stateRightInfo]) show_in_right_side = YES;
	if(state == [m_dualpane stateRightView]) show_in_right_side = YES;

	NSEvent* event = [NSApp currentEvent];

	NSColor* color0 = [NSColor whiteColor];
	NSMutableDictionary* attr0 = [[[NSMutableDictionary alloc] init] autorelease];
	[attr0 setObject:color0 forKey:NSForegroundColorAttributeName];
	[attr0 setObject:[NSFont systemFontOfSize:18] forKey:NSFontAttributeName];
	NSString* sx = @"/usr/local/oiuxcv/oiucx/nnwemn/bin/X11/tmp/wine/xyz/var";

	NSRect textview_frame = NSMakeRect(0, 0, 500, 50);
	
	
	NSView* mcw = [[self window] contentView];
	NSPoint buttonPoint = NSMakePoint( NSMidX([mcw frame]), NSMidY([mcw frame]) );
	if(show_in_left_side) {
		buttonPoint = [m_list_panel_controller_left tabAttachmentPoint];
		buttonPoint = [mcw convertPoint:buttonPoint fromView:[m_list_panel_controller_left view]];
	}
	if(show_in_right_side) {
		buttonPoint = [m_list_panel_controller_right tabAttachmentPoint];
		buttonPoint = [mcw convertPoint:buttonPoint fromView:[m_list_panel_controller_right view]];
	}
	
	NSTextView* textview = [[[NSTextView alloc] initWithFrame:textview_frame] autorelease];
	[textview setDrawsBackground:NO];
	{
		NSAttributedString* as = [[[NSAttributedString alloc] 
			initWithString:sx attributes:attr0] autorelease];
		[[textview textStorage] setAttributedString:as];
	}

    MAAttachedWindow* w = [[MAAttachedWindow alloc] initWithView:textview 
                                            attachedToPoint:buttonPoint 
                                                   inWindow:[self window] 
                                                     onSide:MAPositionBottomRight 
                                                 atDistance:15];
    [w setBorderColor:[NSColor whiteColor]];
    [w setBackgroundColor:[NSColor colorWithCalibratedWhite:0.1 alpha:0.750]];
    [w setViewMargin:20];
    [w setBorderWidth:2];
    [w setCornerRadius:10];
    [w setHasArrow:YES];
    [w setDrawsRoundCornerBesideArrow:YES];
    [w setArrowBaseWidth:30];
    [w setArrowHeight:15];

	[[self window] addChildWindow:w ordered:NSWindowAbove];
    

	do {
		NSEventType event_type = [event type];
		if(event_type == NSKeyDown) {
			int kc = [event keyCode];
			LOG_DEBUG(@"loop down: %i", kc);


			if(kc == 48) {
				m_snapshot_index++;
				if(m_snapshot_index >= n) m_snapshot_index = 0;

				{
					int tab_index = m_snapshot_index + 1;
					NSString* s = [NSString stringWithFormat:@"tab %i", tab_index];
					NSAttributedString* as = [[[NSAttributedString alloc] 
						initWithString:s attributes:attr0] autorelease];
					[[textview textStorage] setAttributedString:as];
					[textview setNeedsDisplay:YES];
					// LOG_DEBUG(@"textview needsdisplay");
				}
			}
            


		} else
		if(event_type == NSKeyUp) {
			int kc = [event keyCode];
			LOG_DEBUG(@"loop up: %i", kc);
			if(kc != 48) {
				break;
			}
			
		} else {
			// discard all other events

			BOOL is_control_modifier2 = (([event modifierFlags] & NSControlKeyMask) != 0);
			if(!is_control_modifier2){
				LOG_DEBUG(@"modifier released");
				break;
			}

			LOG_DEBUG(@"loop discard");

		}
        event = [[self window] nextEventMatchingMask:NSAnyEventMask];
	} while(event);

    [[self window] removeChildWindow:w];
    [w orderOut:self];
    [w release];


	[self loadSnapshot];
#endif // USE_OLD_TAB_CODE
}
#endif


-(void)save {
	// remembers the column widths and column ordering and which ones are hidden
	[m_list_panel_controller_left saveColumnLayout];
	[m_list_panel_controller_right saveColumnLayout];

	// remember the paths
	[m_list_panel_controller_left saveTabState];
	[m_list_panel_controller_right saveTabState];
	
	// remembers whether left-panel or right-panel was active
	[m_dualpane saveState];
}



#ifdef CUSTOM_WINDOW_BACKGROUND

#pragma mark -
#pragma mark Custom window background

- (float)roundedCornerRadius
{
	return 2.f;
}

- (void)drawRect:(NSRect)rect
{
	// Call original drawing method
	[self drawRectOriginal:rect];

	if (!isDrawingCustomFrame)	return;

	//
	// Build clipping path : intersection of frame clip (bezier path with rounded corners) and rect argument
	//
	NSRect windowRect = [[self window] frame];
	windowRect.origin = NSMakePoint(0, 0);

	float cornerRadius = [self roundedCornerRadius];
	[[NSBezierPath bezierPathWithRoundedRect:windowRect xRadius:cornerRadius yRadius:cornerRadius] addClip];
	[[NSBezierPath bezierPathWithRect:rect] addClip];

	//
	// Draw background image (extend drawing rect : biggest rect dimension become's rect size)
	//
	NSRect imageRect = windowRect;
	if (imageRect.size.width > imageRect.size.height)
	{
		imageRect.origin.y = -(imageRect.size.width-imageRect.size.height)/2;
		imageRect.size.height = imageRect.size.width;
	}
	else
	{
		imageRect.origin.x = -(imageRect.size.height-imageRect.size.width)/2;
		imageRect.size.width = imageRect.size.height;
	}
	// [[NSImage imageNamed:NSImageNameActionTemplate] drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceAtop fraction:0.15];

	//
	// Draw a background color on top of everything
	//
	// CGContextRef context = [[NSGraphicsContext currentContext]graphicsPort];
	// CGContextSetBlendMode(context, kCGBlendModeColorDodge);
	// [[NSColor colorWithCalibratedRed:0.7 green:0.4 blue:0 alpha:0.4] set];
	// [[NSColor greenColor] set];
	// [[NSBezierPath bezierPathWithRect:rect] fill];
	
	// NSGradient* grad = [NSGradient blackDividerGradient];
	NSGradient* grad = [NSGradient blackWindowGradient];
	// NSGradient* grad = [NSGradient blueSelectedRowGradient];
	NSRect rect_top, rect_bottom;
	NSDivideRect(windowRect, &rect_top, &rect_bottom, 100, NSMaxYEdge);
    [grad drawInRect:rect_top angle:270.0];
}

#endif // CUSTOM_WINDOW_BACKGROUND

#pragma mark -
#pragma mark NCMainWindow callback for flags changed

-(void)flagsChangedInWindow:(NSWindow*)window {
	// LOG_DEBUG(@"flags changed");
	
	if(window != [self window]) {
		// LOG_DEBUG(@"not our window!");
		return;
	}
	[m_toolbar update];
}

#pragma mark -
#pragma mark Event handling


-(NCListPanelController*)activePanel {
	NCDualPaneState* state = [m_dualpane state];
	if([state leftActive])  return m_list_panel_controller_left;
	if([state rightActive]) return m_list_panel_controller_right;
	return nil;
}

-(NCListPanelController*)otherPanel {
	NCDualPaneState* state = [m_dualpane state];
	if(state == [m_dualpane stateLeftList])  return m_list_panel_controller_right;
	if(state == [m_dualpane stateRightList]) return m_list_panel_controller_left;
	return nil;
}

-(IBAction)gotoFolderAction:(id)sender {
	NCListPanelController* active_panel = [self activePanel];
	if(!active_panel) {
		LOG_DEBUG(@"goto folder is not possible, since no lister is active");
		return;
	}                          
	
	[active_panel showGotoFolderSheet];
}

-(IBAction)changePermissionAction:(id)sender {
	LOG_DEBUG(@"TODO: implement the permission sheet");

	NCListPanelController* active_panel = [self activePanel];
	if(!active_panel) {
		LOG_DEBUG(@"change permission is not possible, since no lister is active");
		return;
	}
	
	//NSArray* names = [active_panel selectedNamesOrCurrentName];
	//NSString* wdir = [active_panel workingDir];

	NCPermissionSheet* sheet = [NCPermissionSheet shared];
	// [sheet setWorkingDir:wdir];
	// [sheet setNames:names];
	// [sheet setDelegate:self];
	[sheet beginSheetForWindow:[self window]];
}

-(IBAction)copyAction:(id)sender {
	NCListPanelController* active_panel = [self activePanel];
	NCListPanelController* other_panel  = [self otherPanel];
	if((!other_panel) || (!active_panel)) {
		// IDEA: show a growl-alert that the F5 shortcut for copy isn't usable
		LOG_DEBUG(@"copy is not possible, since we are not in a list list state");
		return;
	}
	
	[NCCopySheet beginSheetForWindow:self.window
						   operation:[active_panel copyOperation]
						   sourceDir:[active_panel workingDir]
						   targetDir:[other_panel workingDir]
							   names:[active_panel selectedNamesOrCurrentName]
				   completionHandler:
	 ^{
		 LOG_DEBUG(@"copy sheet did close");
	 }];
}

-(IBAction)moveAction:(id)sender {
	NCListPanelController* active_panel = [self activePanel];
	NCListPanelController* other_panel  = [self otherPanel];
	if((!other_panel) || (!active_panel)) {
		// IDEA: show a growl-alert that the F6 shortcut for move isn't usable
		LOG_DEBUG(@"move is not possible, since we are not in a list list state");
		return;
	}
	
	[NCMoveSheet beginSheetForWindow:self.window
						   operation:[active_panel moveOperation]
						   sourceDir:[active_panel workingDir]
						   targetDir:[other_panel workingDir]
							   names:[active_panel selectedNamesOrCurrentName]
				   completionHandler:
	 ^{
		 LOG_DEBUG(@"move sheet did close");
	 }];
}



-(IBAction)makeDirAction:(id)sender {
	NCListPanelController* panel = [self activePanel];
	if(!panel) {
		LOG_DEBUG(@"makedir is not possible, since we are not in a list state");
		return;
	}

	NCMakeDirController* sheet = [NCMakeDirController shared];
	[sheet setWorkingDir:[panel workingDir]];
	[sheet setSuggestName:[panel currentName]];
	[sheet setDelegate:self];
	[sheet beginSheetForWindow:[self window]];
}

-(void)makeDirController:(NCMakeDirController*)ctrl didMakeDir:(NSString*)path {
	// IDEA: full reload is overkill, ideally we should only reload one of the panels
	[self fullReload];
}

-(IBAction)makeFileAction:(id)sender {
	NCListPanelController* panel = [self activePanel];
	if(!panel) {
		LOG_DEBUG(@"makefile is not possible, since we are not in a list state");
		return;
	}

	NCMakeFileController* sheet = [NCMakeFileController shared];
	[sheet setWorkingDir:[panel workingDir]];
	[sheet setSuggestName:[panel currentName]];
	[sheet setDelegate:self];
	[sheet beginSheetForWindow:[self window]];
}

-(void)makeFileController:(NCMakeFileController*)ctrl didMakeFile:(NSString*)path {
	// IDEA: full reload is overkill, ideally we should only reload one of the panels
	[self fullReload];
}

-(IBAction)makeLinkAction:(id)sender {
	NCListPanelController* active_panel = [self activePanel];
	NCListPanelController* other_panel  = [self otherPanel];
	if((!other_panel) || (!active_panel)) {
		LOG_DEBUG(@"makelink is not possible, since we are not in a list list state");
		return;
	}

	NSString* wdir = [active_panel workingDir];
	NSString* target_name = [other_panel currentName];
	NSString* target_wdir = [other_panel workingDir];
	NSString* target = target_wdir;
	if(!target_name) {
		target_name = [target_wdir lastPathComponent];
	} else {
		target = [target_wdir stringByAppendingPathComponent:target_name];
	}

	NCMakeLinkController* ctrl = [NCMakeLinkController shared];
	[ctrl setWorkingDir:wdir];
	[ctrl setLinkName:target_name];
	[ctrl setLinkTarget:target];
	[ctrl setDelegate:self];
	[ctrl beginSheetForWindow:[self window]];
}

-(void)makeLinkController:(NCMakeLinkController*)ctrl didMakeLink:(NSString*)path {
	// IDEA: full reload is overkill, ideally we should only reload one of the panels
	[self fullReload];
}

-(IBAction)deleteAction:(id)sender {
	NCListPanelController* active_panel = [self activePanel];
	if(!active_panel) {
		LOG_DEBUG(@"delete is not possible, since there is no active panel");
		return;
	}
	NSArray* names = [active_panel selectedNamesOrCurrentName];
	if([names count] < 1) {
		LOG_DEBUG(@"delete is not possible, since there are no selected items");
		return;
	}

	NSString* wdir = [active_panel workingDir];
	
	NSArray* paths = [names prependPath:wdir];
	// LOG_DEBUG(@"paths: %@", paths);
	
	NCDeleteSheet* ctrl = [NCDeleteSheet shared];
	[ctrl setPaths:paths];
	[ctrl setDelegate:self];
	[ctrl beginSheetForWindow:[self window]];
}

-(void)deleteControllerDidDelete:(NCDeleteSheet*)ctrl {
	// IDEA: full reload is overkill, ideally we should only reload one of the panels
	[self fullReload];
}

-(void)didClickToolbarItem:(int)tag {
	switch(tag) {
	case kNCMakeDirToolbarItemTag: [self makeDirAction:self]; break;
	case kNCMakeFileToolbarItemTag: [self makeFileAction:self]; break;
	case kNCCopyToolbarItemTag: [self copyAction:self]; break;
	case kNCMoveToolbarItemTag: [self moveAction:self]; break;
	case kNCDeleteToolbarItemTag: [self deleteAction:self]; break;
	case kNCReloadToolbarItemTag: [self fullReload]; break;
	case kNCRenameToolbarItemTag: [self renameAction:self]; break;
	default: {
		LOG_DEBUG(@"ERROR: unknown tag: %i", tag);
		break; }
	}
}

-(void)switchToUser:(int)user_id {
	// LOG_DEBUG(@"switch to user id: %i", user_id);
	NCListPanelController* active_panel = [self activePanel];
	if(!active_panel) {
		LOG_DEBUG(@"switch user is not possible, since there is no active panel");
		return;
	}
	[active_panel switchToUser:user_id];
}

-(IBAction)renameAction:(id)sender {
	NCListPanelController* panel = [self activePanel];
	if(!panel) {
		LOG_DEBUG(@"rename is not possible, since there is no active panel");
		return;
	}
	[panel enterRenameMode];
}

-(IBAction)openInTerminal:(id)sender {
	NCListPanelController* active_panel = [self activePanel];
	if(!active_panel) {
		LOG_DEBUG(@"open in terminal is not possible, since there is no active panel");
		return;
	}
	[self openTerminalWithPath:[active_panel workingDir]];
}

-(BOOL)openTerminalWithPath:(NSString*)aPath {
	@try {
		TerminalApplication* terminal = [SBApplication applicationWithBundleIdentifier:@"com.apple.Terminal"];
        [terminal activate];
		[terminal open:[NSArray arrayWithObject:aPath]];
		return YES;
	} @catch(id ue) {
		return NO;
	} @finally {
		return NO;
	}
}

@end
