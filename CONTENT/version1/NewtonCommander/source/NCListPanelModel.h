//
//  NCListPanelModel.h
//  NewtonCommander
//
//  Created by Simon Strandgaard on 12/03/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NCListPanelModel : NSObject {
	int m_number_of_dirs;
	int m_number_of_selected_dirs;
	int m_number_of_files;
	int m_number_of_selected_files;
	unsigned long long m_size_of_items;
	unsigned long long m_size_of_selected_items; 
	NSString* m_working_dir;
}
@property int numberOfDirs;
@property int numberOfSelectedDirs;
@property int numberOfFiles;
@property int numberOfSelectedFiles;
@property unsigned long long sizeOfItems;
@property unsigned long long sizeOfSelectedItems;
@property(nonatomic, retain) NSString* workingDir;

@end
