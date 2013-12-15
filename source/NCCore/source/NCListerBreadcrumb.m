//
//  NCListerBreadcrumb.m
//  NCCore
//
//  Created by Simon Strandgaard on 20/03/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "NCListerBreadcrumb.h"


@implementation NCListerBreadcrumb

@synthesize workingDir = m_working_dir;
@synthesize date = m_date;
@synthesize selectedRow = m_selected_row;
@synthesize numberOfRows = m_number_of_rows;
@synthesize positionY = m_position_y;
@synthesize currentName = m_current_name;
@synthesize items = m_items;

-(NSString*)description { 
	NSString* item_status = @"nil";
	if(m_items) {
		item_status = [NSString stringWithFormat:@"ARRAY_OF_SIZE_%i", (int)[m_items count]];
	}
	return [NSString stringWithFormat:
		@"wdir: %@  date: %@  selected %i of %i rows  scroll: %.2f  currentName: %@  items: %@", 
		m_working_dir,
		[m_date descriptionWithCalendarFormat:@"%H:%M:%S" timeZone:nil locale:nil],
		m_selected_row, 
		m_number_of_rows, 
		m_position_y,
		m_current_name,
		item_status
	];
}

@end

@implementation NCListerBreadcrumbStack

@synthesize breadcrumbs = m_breadcrumbs;

-(id)init {
	self = [super init];
    if(self) {
		[self setBreadcrumbs:[NSMutableArray array]];
    }
    return self;
}


-(NSString*)description { 
	return [NSString stringWithFormat:
		@"Breadcrumbs: %@", 
		m_breadcrumbs
	];
}

-(void)pushBreadcrumb:(NCListerBreadcrumb*)crumb {
	[m_breadcrumbs addObject:crumb];
}

-(NCListerBreadcrumb*)popBreadcrumb {
	if([m_breadcrumbs count] < 1) {
		return nil; // stack is empty
	}
	NCListerBreadcrumb* crumb = [m_breadcrumbs lastObject];
	[m_breadcrumbs removeLastObject];
	return crumb;
}

-(void)removeAllObjects {
	[m_breadcrumbs removeAllObjects];
}

@end
