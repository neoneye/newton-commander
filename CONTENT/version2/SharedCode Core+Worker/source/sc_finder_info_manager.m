#import "sc_finder_info_manager.h"
#import <CoreServices/CoreServices.h>

@implementation FinderInfoManager

+(FinderInfoManager*)shared {
    static FinderInfoManager* shared = nil;
    if(!shared) {
        shared = [[FinderInfoManager alloc] init];
    }
    return shared;
}

-(void)copyFrom:(NSString*)fromPath to:(NSString*)toPath {
	const char* source_path = [fromPath fileSystemRepresentation];
	const char* target_path = [toPath fileSystemRepresentation];

	FSRef source_ref;
	OSStatus status = FSPathMakeRef((unsigned char*)source_path, &source_ref, NULL);
	if(status != noErr) {
		NSLog(@"%@ FSPathMakeRef", NSStringFromSelector(_cmd));
    	return;
  	}

	FSRef target_ref;
	status = FSPathMakeRef((unsigned char*)target_path, &target_ref, NULL);
	if(status != noErr) {
		NSLog(@"%@ FSPathMakeRef", NSStringFromSelector(_cmd));
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
		NSLog(@"%@ FSGetCatalogInfo", NSStringFromSelector(_cmd));
		return;
	}

	status = FSSetCatalogInfo(
		&target_ref, 
		kFSCatInfoFinderInfo, 
		&info
	);
	if(status != noErr) {
		NSLog(@"%@ FSSetCatalogInfo", NSStringFromSelector(_cmd));
		return;
	}
}

@end // @implementation FinderInfoManager
