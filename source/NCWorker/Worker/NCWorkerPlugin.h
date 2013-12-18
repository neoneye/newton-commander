//
// NCWorkerPlugin.h
// Newton Commander
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
