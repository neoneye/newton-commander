/*********************************************************************
JFSystemCopy.h - threaded wrapper around the lowlevel copy code

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/

struct JFSystemCopyState {
	unsigned long long bytes_copied;
	
};

@class JFSystemCopyThread;
@interface JFSystemCopy : NSObject {
	id m_delegate;

	NSThread* m_thread;
	JFSystemCopyThread* m_system_copy_thread;
	
	NSTimer* m_debug_timer;
	unsigned int m_debug_timer_tick;

	NSArray* m_names;
	unsigned int m_name_index;
	
	NSString* m_source_dir;
	NSString* m_target_dir;


	// current status
	NSTimer* m_timer;
	NSString* m_current_item_name;
	float m_current_progress;
	unsigned long long m_bytes_transfered;
	unsigned long long m_bytes_total;
	float m_bytes_per_second;
	float m_seconds_remaining;
}
@property (nonatomic, assign) id delegate;
@property (copy) NSArray* names;
@property (copy) NSString* sourceDir;
@property (copy) NSString* targetDir;

-(void)startThread;
-(void)prepare;

-(void)start;
-(void)abort;
-(void)stop;

-(void)setNames:(NSArray*)names;


-(float)progress;
-(NSString*)currentItemName;
-(unsigned long long)bytesTransfered;
-(unsigned long long)bytesTotal;
-(float)bytesPerSecond;
-(float)secondsRemaining;
@end


@interface NSObject (JFSystemCopyDelegate)
-(void)copyActivity:(JFSystemCopy*)sysCopy;
-(void)copyDidComplete:(JFSystemCopy*)sysCopy;

-(void)copy:(JFSystemCopy*)sysCopy willScanName:(NSString*)name;

-(void)copy:(JFSystemCopy*)sysCopy nowScanningName:(NSString*)name
       size:(unsigned long long)bytes
       count:(unsigned long long)count;

-(void)copy:(JFSystemCopy*)sysCopy didScanName:(NSString*)name
       size:(unsigned long long)bytes
       count:(unsigned long long)count;

-(void)copy:(JFSystemCopy*)sysCopy
	updateScanSummarySize:(unsigned long long)bytes 
	count:(unsigned long long)count;

-(void)copy:(JFSystemCopy*)sysCopy
	scanSummarySize:(unsigned long long)bytes 
	count:(unsigned long long)count;


-(void)readyToCopy:(JFSystemCopy*)sysCopy;
-(void)copy:(JFSystemCopy*)sysCopy willCopyName:(NSString*)name;
-(void)copy:(JFSystemCopy*)sysCopy didCopyName:(NSString*)name;
-(void)copy:(JFSystemCopy*)sysCopy nowCopyingItem:(NSString*)item;
-(void)copy:(JFSystemCopy*)sysCopy transferedBytes:(unsigned long long)bytes;
-(void)copy:(JFSystemCopy*)sysCopy bytesPerSecond:(double)bps;
-(void)copy:(JFSystemCopy*)sysCopy copyingName:(NSString*)name progress:(double)progress;

-(void)copy:(JFSystemCopy*)sysCopy willCopy:(NSString*)name;
-(void)copy:(JFSystemCopy*)sysCopy didCopy:(NSString*)name;
-(void)copy:(JFSystemCopy*)sysCopy name:(NSString*)name copyState:(JFSystemCopyState)state;

-(void)copyCompleted:(JFSystemCopy*)sysCopy
	bytes:(unsigned long long)bytes
	elapsed:(double)elapsed;
@end
