//
//  NCListerBreadcrumb.h
//  NCCore
//
//  Created by Simon Strandgaard on 20/03/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NCListerBreadcrumb : NSObject {
	NSString* m_working_dir;
	
	// timestamp when the breadcrumb was last used
	NSDate* m_date;
	
	int m_selected_row;
	
	int m_number_of_rows;

	/*
	PROBLEM: if we store the visible rect, then we can restore the pixel position 
	assuming the window is NOT resized. However our window IS resizable, so we 
	will have to solve it in another way.
	SOLUTION: store a percentage for the y position.
	  0% = top of scrollview
	 50% = middle of scrollview
	100% = bottom of scrollview
	*/
	float m_position_y;
	
	/*
	PROBLEM: if we don't keep track of the currently selected name, and
	at some point navigates back to a dir that we have been at some time ago.
	If this dir have changed, then we cannot select the same file again.
	SOLUTION: keeping track of the current name, makes it possible for us
	to select the same item. Giving a much better user experience.
	*/
	NSString* m_current_name;
	
	/*
	PROBLEM: if we don't cache the item names, then the user will have
	to wait for up to 1 second when ever the user presses BACKSPACE.
	SOLUTION: caching the item names saves precious time.
	Giving a much better user experience.
	*/
	NSArray* m_items;
	
	
	/*
	IDEA: remember selectedNames, so that the selectedIndexes can be restored
	even though there have been changes to the dir.
	*/
}
@property (strong) NSString* workingDir;
@property (strong) NSDate* date;
@property int selectedRow;
@property int numberOfRows;
@property float positionY;
@property (strong) NSArray* items;
@property (strong) NSString* currentName;

@end


/*
Breadcrumbs is a stack.
When you navigate-into-a-dir then you push a breadcrumb on the stack.
When you navigate-out-of-a-dir then you pop a breadcrumb from the stack.
When you navigate to another dir then you kill the stack and insert breadcrumbs for all its parent dirs.
*/
@interface NCListerBreadcrumbStack : NSObject {
	NSMutableArray* m_breadcrumbs;
}
@property (strong) NSMutableArray* breadcrumbs;

-(void)pushBreadcrumb:(NCListerBreadcrumb*)crumb;
-(NCListerBreadcrumb*)popBreadcrumb;
-(void)removeAllObjects;

@end
