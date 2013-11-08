//
//  AppDelegate.m
//  OpenDir
//
//  Created by Simon Strandgaard on 6/12/12.
//  Copyright (c) 2012 opcoders. All rights reserved.
//

#import "AppDelegate.h"

#include <dirent.h>

@implementation AppDelegate

@synthesize window = _window;


-(void)list:(NSString*)path {
    NSLog(@"LIST: %@     BEFORE", path);
    DIR *dirp = opendir([path fileSystemRepresentation]);
    if(!dirp) {
        NSLog(@"Error");
        return;
    }
    
    while(1) {
        struct dirent *dptr = readdir(dirp);
        if (!dptr) {
            break;
        }
        
        NSLog(@"%s\n",dptr->d_name);
    }
    
    closedir(dirp);
    NSLog(@"LIST: %@     AFTER", path);
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    

    [self list:NSHomeDirectory()];
    [self list:@"/"];
    [self list:NSTemporaryDirectory()];
    
}

@end
