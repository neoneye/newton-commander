#include <Foundation/Foundation.h>

@interface FinderInfoManager : NSObject {
}
+(FinderInfoManager*)shared;

/*
TODO: copy between filedescriptors
*/
-(void)copyFrom:(NSString*)fromPath to:(NSString*)toPath;

@end
