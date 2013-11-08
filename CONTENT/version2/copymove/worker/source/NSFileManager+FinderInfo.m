//
//  NSFileManager+FinderInfo.m
//  worker
//
//  Created by Simon Strandgaard on 22/05/11.
//  Copyright 2011 opcoders.com. All rights reserved.
//

#import "NSFileManager+FinderInfo.h"
#import <CoreServices/CoreServices.h>


@implementation NSFileManager (FinderInfo)

-(void)copyFinderInfoFrom:(NSString*)fromPath to:(NSString*)toPath {
	const char* source_path = [fromPath fileSystemRepresentation];
	const char* target_path = [toPath fileSystemRepresentation];

	FSRef source_ref;
	OSStatus status = FSPathMakeRef((unsigned char*)source_path, &source_ref, NULL);
	if(status != noErr) {
		NSLog(@"%s FSPathMakeRef", _cmd);
    	return;
  	}

	FSRef target_ref;
	status = FSPathMakeRef((unsigned char*)target_path, &target_ref, NULL);
	if(status != noErr) {
		NSLog(@"%s FSPathMakeRef", _cmd);
    	return;
  	}

	FSCatalogInfo info;
	status = FSGetCatalogInfo(
		&source_ref, 
		kFSCatInfoFinderInfo,
		&info, 
		NULL,
		NULL,
		NULL
	);
	if(status != noErr) {
		NSLog(@"%s FSGetCatalogInfo", _cmd);
		return;
	}

	status = FSSetCatalogInfo(
		&target_ref, 
		kFSCatInfoFinderInfo, 
		&info
	);
	if(status != noErr) {
		NSLog(@"%s FSSetCatalogInfo", _cmd);
		return;
	}
}


@end
