//
//  WorkerParentAuthorization.h
//  Kill
//
//  Created by Simon Strandgaard on 11/06/11.
//  Copyright 2011 opcoders.com. All rights reserved.
//

#include <Foundation/Foundation.h>


/*
The purpose with WorkerParentAuthorization is all about recycling the authentication reference,
so that the user only have to enter the password a single time.
Before this class existed the user had to enter the admin password whenever
a new child process had to be started. This was really annoying.
*/
@interface WorkerParentAuthorization : NSObject {
	AuthorizationRef m_auth;
}
+(WorkerParentAuthorization*)shared;

-(BOOL)createAuthorization;
-(void)invalidateAuthorization;

-(void)execute:(NSString*)executablePath arguments:(NSArray*)arguments;

@end
