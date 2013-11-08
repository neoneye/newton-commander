//
//  NCWorkerPlugin.h
//  NCWorker
//
//  Created by Simon Strandgaard on 16/07/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//


// forward
@protocol NCWorkerPluginDelegate;

@protocol NCWorkerPlugin

-(void)setDelegate:(id<NCWorkerPluginDelegate>)delegate;

-(void)request:(NSDictionary*)dict;

@end

#pragma mark -

@protocol NCWorkerPluginDelegate

-(void)plugin:(id<NCWorkerPlugin>)plugin response:(NSDictionary*)dict;

@end
