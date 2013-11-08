//
//  NCTimeProfiler.h
//  NCCore
//
//  Created by Simon Strandgaard on 14/07/10.
//  Copyright 2010 opcoders.com. All rights reserved.
//

#import <Foundation/Foundation.h>


// Raw mach_absolute_times going in, difference in seconds out
double subtract_times( uint64_t endTime, uint64_t startTime );


@class FPOCsvWriter;
@interface NCTimeProfilerShared : NSObject {
	NSFileHandle* m_handle;
	FPOCsvWriter* m_writer;
}
@property (retain) NSFileHandle* handle;
@property (retain) FPOCsvWriter* writer;
// +(NCTimeProfilerShared*)shared;
-(void)writeRow:(NSArray *)row;

@end

@interface NCTimeProfiler : NSObject {
	NSMutableDictionary* m_start_time;
	NSMutableDictionary* m_stop_time;          
	NSMutableDictionary* m_elapsed_time;
	NSMutableDictionary* m_info;
}

-(void)setObject:(id)obj forKey:(NSString*)key;

// start a named counter
-(void)startCounter:(NSString*)counterName;

// stop a named counter
// returns elapsed time
-(double)stopCounter:(NSString*)counterName;


// start the default counter
-(void)start;

// stop the default counter
// returns elapsed time
-(double)stop;

@end

@interface NCTimeProfilerSetWorkingDir : NCTimeProfiler {

}

-(NSArray*)headers;
-(NSArray*)columns;

@end
