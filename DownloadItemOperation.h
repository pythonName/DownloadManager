//
//  DownloadItemOperationInfo.h
//  downloadTest
//
//  Created by apple on 12-8-18.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//
#import "NSURLSession+CorrectedResumeData.h"


typedef enum {
    kDownloadItemOperationNoInDownloading = -2,
    kDownloadItemOperationPausedState = -1,
    kDownloadItemOperationExecutingState,
    kDownloadItemOperationFinishedState,
    kDownloadItemOperationFaildState,
    kDownloadItemOperationWaitingState,
}DownloadItemOperationState;

#define IS_IOS10ORLATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10)
@interface DownloadItemOperation : NSObject//<NSCoding>

@property (nonatomic, copy) NSString *uniqueID;//作为每个下载的唯一标示
@property (nonatomic,assign) NSUInteger taskIdentifier;//实际对应的task的唯一标示
@property (nonatomic, strong) NSData *resumeData;
@property (nonatomic, assign) DownloadItemOperationState state;//下载状态
@property (nonatomic, copy) NSString *url;//下载包地址
@property (nonatomic, copy) NSString *fileSavePath;//文件下载完成后保存的路径
@property (nonatomic, strong) NSFileHandle *fileHandle;//文件操作句柄
//下载进度相关属性
@property (nonatomic, assign) long long fileTotalSize;//文件总大小
@property (nonatomic, assign) long long fileProgressSize;//已下载的文件的大小
@property (nonatomic,assign) NSTimeInterval downloadStartTime;
@property (nonatomic, assign) long long lastDownloadFileProgressSize;//上一次下载的 已经下载的大小

- (id)initWithUrl:(NSString *)url
         uniqueID:(NSString *)uniqueID;

- (void)startOperation:(BOOL)isBreakPointDownload;
- (void)pauseOperation;
- (void)continueOperation;
- (void)cancelOperation;

- (NSURLSessionDataTask *)returnTask;
- (void)setInTask:(NSURLSessionDataTask *)task;

@end

