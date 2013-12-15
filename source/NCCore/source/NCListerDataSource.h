//
//  NCListerDataSource.h
//  NCCore
//
//  Created by Simon Strandgaard on 10/07/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

// forward
@protocol NCListerDataSourceDelegate;

@protocol NCListerDataSource <NSObject>

-(void)setDelegate:(id<NCListerDataSourceDelegate>)delegate;

-(void)setWorkingDir:(NSString*)path;
-(void)reload;

@end



#pragma mark -

@protocol NCListerDataSourceDelegate <NSObject>

-(void)listerDataSource:(id<NCListerDataSource>)dataSource resolvedPath:(NSString*)path;

-(void)listerDataSource:(id<NCListerDataSource>)dataSource updateItems:(NSArray*)items progress:(NSUInteger)progress;

-(void)listerDataSourceFinishedLoading:(id<NCListerDataSource>)dataSource;

-(void)fileSystemDidChange:(id<NCListerDataSource>)dataSource;

@end
