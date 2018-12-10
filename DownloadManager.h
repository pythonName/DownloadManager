//
//  MultiThreadDownloadManager.h
//  downloadTest
//
//  Created by apple on 12-8-4.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "AppDownloadItemOperation.h"
#import "BaseManager.h"

#define kDownloadInfoCacheSaveFolder @"DownloadQueueCache"
#define kDowloadWaitingCacheFileName @"CacheDownloadWaiting"

@interface DownloadManager : BaseManager

@property (atomic, strong) NSMutableArray *downloadQueue; //整个下载队列数组
@property (nonatomic,strong) NSURLSession *sharedSession;//所有下载共享一个session
//@property (atomic, strong) NSMutableArray *downloadwaitingQueue; //正在等待的
@property (nonatomic,strong) NSURLSession *sharedSessionForeground;//前台session
//+ (DownloadManager *)sharedInstance;
@property (nonatomic,assign) BOOL isEnterBackground;

- (BOOL)addAppDownloadItem:(AppDownloadItemOperation *)item;

- (void)cancelDownloadItemWithAppId:(NSString *)appId;
- (void)cancelAllDownloadItem;

- (void)startDownloadOperation:(NSString *)appId;
- (void)startAllDownloadOperation;
//- (void)reStartDownloadOperation:(NSString *)appId;
- (void)pauseDownloadOperation:(NSString *)appId;
- (void)pauseAllDownloadOperation;

- (void)continueDownloadOperation:(NSString *)appId;

- (int)getDownloadingItemCount;

- (AppDownloadItemOperation *)getDownloadItemAtIndex:(NSInteger)index;
- (AppDownloadItemOperation *)getDownloadItemWithAppID:(NSString *)appId;
- (AppDownloadItemOperation *)getDownloadItemWithTaskIdentifier:(NSUInteger)identifier;

- (BOOL)hasItemDownloading;//队列中是否有正在下载中的操作，若有 则下载中页面左上角显示“暂停所有” 否则“开始所有”

- (int)downloadItemIndexOfObject:(AppDownloadItemOperation *)downloadItemOperation;
- (BOOL)isAttainMaxDownlodCount;
- (void)archiverThisOper:(AppDownloadItemOperation *)item;
- (void)removeArchiverThisOper:(AppDownloadItemOperation *)item;
- (void)stratNextReadyOperation;

@end


@protocol DownloadManagerDelegate <NSObject>

@optional
- (void)downloadReady:(AppDownloadItemOperation *)downloadItem;
- (void)downloadPause:(AppDownloadItemOperation *)downloadItem;
- (void)downloadResume:(AppDownloadItemOperation *)downloadItem;
- (void)downloadCancel:(AppDownloadItemOperation *)downloadItem;
- (void)downloadHandleFromAppStore:(AppDownloadItemOperation *)downloadItem;
- (void)downloadReNeedAuthorization;
- (void)downloadCancelSomeDownload:(NSArray *)downloadItems;
- (void)downloadCancelAllDownload;
- (void)downloadProgress:(AppDownloadItemOperation *)downloadItem;
- (void)downloadCompletion:(AppDownloadItemOperation *)downloadItem;
- (void)downloadFailed:(AppDownloadItemOperation *)downloadItem error:(NSError *)error;

- (void)downloadWish:(AppDownloadItemOperation *)downloadItem;
- (void)downloadUploadingInstallPlistFile:(AppDownloadItemOperation *)downloadItem;
@end
