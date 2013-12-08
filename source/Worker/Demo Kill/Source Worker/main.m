/*

*/
#import "WorkerChild.h"
#import "Logger.h"

@interface MyWorkerPlugin : NSObject <WorkerChildPlugin>
@end

@implementation MyWorkerPlugin

-(void)prepareWorkerChild:(WorkerChild*)aWorkerChild {
	// LOG_DEBUG(@"workerChild: %@", aWorkerChild);
	
	[aWorkerChild registerCommand:@"test1" block:^(NSDictionary* aDictionary){
		NSArray* keys = [NSArray arrayWithObjects:@"command", @"message", nil];
		NSArray* objects = [NSArray arrayWithObjects:@"test1", @"hello world from test1", nil];
		NSDictionary* dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];	
		[aWorkerChild deliverResponse:dict];
	}];

	[aWorkerChild registerCommand:@"test2" block:^(NSDictionary* aDictionary){
		NSArray* keys = [NSArray arrayWithObjects:@"command", @"message", nil];
		NSArray* objects = [NSArray arrayWithObjects:@"test2", @"hello world from test2", nil];
		NSDictionary* dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];	
		[aWorkerChild deliverResponse:dict];
	}];

}

@end


int main(int argc, const char * argv[]) {
	return worker_child_main(
		argc, 
		argv, 
		"KillWorker", 
		"MyWorkerPlugin"
	);
}
