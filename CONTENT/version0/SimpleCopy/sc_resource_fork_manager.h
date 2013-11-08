#include <Foundation/Foundation.h>

@interface ResourceForkManager : NSObject {
}
+(ResourceForkManager*)shared;

-(NSData*)getResourceForkFromFile:(NSString*)path;
-(void)setResourceFork:(NSData*)data onFile:(NSString*)path;

/*
TODO: copy between filedescriptors
*/
-(void)copyFrom:(NSString*)fromPath to:(NSString*)toPath;

@end
