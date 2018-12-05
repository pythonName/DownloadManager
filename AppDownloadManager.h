//
//  AppDownloadManager.h
//

#import <Foundation/Foundation.h>
#import "DownloadManager.h"
#import "AppDownloadItemOperation.h"
@interface AppDownloadManager : DownloadManager

@property (atomic, strong) NSMutableData *receiveData;
@property (atomic,assign) CGFloat downloadingDiskSpace;//下载队列整个的占用量 单位：M

+ (AppDownloadManager *)sharedInstance;
-(BOOL)addAppDownloadItem:(AppDownloadItemOperation *)item;//普通下载
//- (CGFloat)getCurrentDownloadOperSize:(AppDownloadItemOperation *)oper;
- (void)cancelAllDownloadItem;

@end
