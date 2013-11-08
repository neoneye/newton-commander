/*********************************************************************
JFSystemCopyThread.h - lowlevel code for copying files

Copyright (c) 2009 - opcoders.com
Simon Strandgaard <simon@opcoders.com>
*********************************************************************/

#define kJFByteSampleCount 32
#define kJFByteSamplePerSec 8

struct JFByteSamples {
	double last_time;
	unsigned long long last_bytes;
	unsigned long long bytes[kJFByteSampleCount];
	unsigned int sample_index;
};

struct JFSystemCopyThreadStatus {
	double bytes_throughput;
	double progress_under_name;
	unsigned long long bytes_transfered;
};

@interface JFSystemCopyThread : NSObject {
	id m_delegate;

	NSString* m_source_dir;
	NSString* m_target_dir;
	NSArray* m_items;
	
	unsigned int m_elements_created;
	unsigned int m_elements_total;
	unsigned int m_elements_under_name;
	unsigned long long m_bytes_copied;
	unsigned long long m_bytes_total; 
	unsigned long long m_bytes_under_name;
	unsigned long long m_bytes_copied_under_name;
	unsigned long long m_bytes_total_under_name;
	
	NSLock* m_is_running_lock;
	BOOL m_is_running;
	
	JFByteSamples m_throughput;
	
	
	NSLock* m_status_lock;
	JFSystemCopyThreadStatus m_status;
}
@property (copy) NSString* sourceDir;
@property (copy) NSString* targetDir;
@property (nonatomic, assign) id delegate;

-(void)prepareCopyFrom:(NSString*)sourceDir to:(NSString*)targetDir names:(NSArray*)names;

-(void)threadMainRoutine;

-(BOOL)isRunning;
-(void)stopRunning;

-(void)start;

-(void)startCopying;

-(BOOL)obtainStatus:(JFSystemCopyThreadStatus*)status;

@end


@interface NSObject (JFSystemCopyThreadDelegate)

-(void)copyThread:(JFSystemCopyThread*)sysCopyThread 
     willScanName:(NSString*)name;

-(void)copyThread:(JFSystemCopyThread*)sysCopyThread 
  nowScanningName:(NSString*)name
             size:(unsigned long long)bytes 
            count:(unsigned long long)count;

-(void)copyThread:(JFSystemCopyThread*)sysCopyThread 
      didScanName:(NSString*)name 
             size:(unsigned long long)bytes 
            count:(unsigned long long)count;

-(void)copyThread:(JFSystemCopyThread*)sysCopyThread 
  updateScanSummarySize:(unsigned long long)bytes 
            count:(unsigned long long)count;

-(void)copyThread:(JFSystemCopyThread*)sysCopyThread 
  scanSummarySize:(unsigned long long)bytes 
            count:(unsigned long long)count;

-(void)copyThreadIsReadyToCopy:(JFSystemCopyThread*)sysCopyThread;

-(void)copyThread:(JFSystemCopyThread*)sysCopyThread 
     willCopyName:(NSString*)name;

-(void)copyThread:(JFSystemCopyThread*)sysCopyThread 
      didCopyName:(NSString*)name;

-(void)copyThread:(JFSystemCopyThread*)sysCopyThread 
   nowCopyingItem:(NSString*)item;

-(void)copyThread:(JFSystemCopyThread*)sysCopyThread 
  transferedBytes:(unsigned long long)bytes;

-(void)copyThread:(JFSystemCopyThread*)sysCopyThread 
   bytesPerSecond:(double)bps;

-(void)copyThreadTransferCompleted:(JFSystemCopyThread*)sysCopyThread
	bytes:(unsigned long long)bytes
	elapsed:(double)elapsed;

@end