//
//  WorkerCommand.h
//  Kill
//
//  Created by Simon Strandgaard on 05/06/11.
//  Copyright 2011 opcoders.com. All rights reserved.
//

#include <Foundation/Foundation.h>


#define kWorkerParentCommandChildDidStart @"child_did_start"
#define kWorkerParentCommandChildDidStop @"child_did_stop"

#define kWorkerChildCommandStartup @"startup"


typedef void (^WorkerDictionaryBlock)(NSDictionary* aDictionary);


/*
Command Pattern, with a block, so that you don't have to subclass.
Instead you just create an instance of WorkerCommand and pass it the
block that should be executed.
*/
@interface WorkerCommand : NSObject {
}
+(WorkerCommand*)commandWithBlock:(WorkerDictionaryBlock)aBlock;
-(void)run:(NSDictionary*)aDictionary;
@end
