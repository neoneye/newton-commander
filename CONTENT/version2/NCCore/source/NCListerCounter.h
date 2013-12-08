//
//  NCListerCounter.h
//  NCCore
//
//  Created by Simon Strandgaard on 15/02/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NCListerCounter : NSView {
	int _numberOfDirs;
	int _numberOfSelectedDirs;
	int _numberOfFiles;
	int _numberOfSelectedFiles;
	unsigned long long _sizeOfItems;
	unsigned long long _sizeOfSelectedItems;
}

@property (nonatomic) int numberOfDirs;
@property (nonatomic) int numberOfSelectedDirs;
@property (nonatomic) int numberOfFiles;
@property (nonatomic) int numberOfSelectedFiles;
@property (nonatomic) unsigned long long sizeOfItems;
@property (nonatomic) unsigned long long sizeOfSelectedItems;

@end
