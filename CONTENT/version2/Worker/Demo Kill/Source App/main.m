//
//  main.m
//  Benchmark
//
//  Created by Simon Strandgaard on 04/06/11.
//  Copyright 2011 opcoders.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WorkerParent.h"


int main(int argc, char *argv[]) {
	PREPARE_WORKER_PARENT_IN_MAIN;	
    return NSApplicationMain(argc,  (const char **) argv);
}
