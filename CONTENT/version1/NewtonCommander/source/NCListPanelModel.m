//
//  NCListPanelModel.m
//  NewtonCommander
//
//  Created by Simon Strandgaard on 12/03/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import "NCListPanelModel.h"


@implementation NCListPanelModel

@synthesize numberOfDirs = m_number_of_dirs;
@synthesize numberOfSelectedDirs = m_number_of_selected_dirs;
@synthesize numberOfFiles = m_number_of_files;
@synthesize numberOfSelectedFiles = m_number_of_selected_files;
@synthesize sizeOfItems = m_size_of_items;
@synthesize sizeOfSelectedItems = m_size_of_selected_items;
@synthesize workingDir = m_working_dir;

-(NSString*)description { 
	return m_working_dir;
}

@end
