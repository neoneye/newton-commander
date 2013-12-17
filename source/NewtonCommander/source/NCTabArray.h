//
//  NCTabArray.h
//  NewtonCommander
//
//  Created by Simon Strandgaard on 07/04/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NCTabArrayItem : NSObject {
	NSString* m_working_dir;
	// TODO: state in opposite panel, 1=lister, 2=viewer, 3=info, 4=edit_permissions, 5=volume_info
	// TODO: breadcrumbs
	// TODO: selected files
	// TODO: vertical scroll position
	// TODO: horizontal scroll position
	NSString* m_cursor_name;
}
@property(nonatomic, strong) NSString* workingDir;
@property(nonatomic, strong) NSString* cursorName;

@end

@interface NCTabArray : NSObject {
	NSString* m_identifier;                    
	NSMutableArray* m_array;
	int m_index;
}
@property(nonatomic, strong) NSString* identifier;

+(NCTabArray*)arrayLeft;
+(NCTabArray*)arrayRight;

/*
working dir for current tab
*/
-(void)setWorkingDir:(NSString*)wdir;
-(NSString*)workingDir;


/*
filename, which the cursor point at
*/
-(void)setCursorName:(NSString*)name;
-(NSString*)cursorName;


-(int)numberOfTabs;
-(int)selectedIndex;

-(void)insertNewTab;        
-(void)firstTab;
-(void)nextTab;
-(void)prevTab;
-(void)closeTab;

-(void)save;
-(void)load;


@end
