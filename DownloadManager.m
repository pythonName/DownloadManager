//
//  MultiThreadDownloadManager.m
//  downloadTest
//
//  Created by apple on 12-8-4.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "DownloadManager.h"
#import "BaseFunc.h"
//#import "FileHash.h"
//#import "IPAUtil.h"
//#import "DNSPodUtil.h"
//#import "VVGlobalDefine.h"
//#import "SettingConfig.h"
//#import "appRecord.h"
//#import "SettingConfig.h"
#include <objc/runtime.h>
#include <stdio.h>
#import "vvDefine.h"
#import "ConfigManager.h"

@interface DownloadManager()<NSURLSessionDelegate,NSURLSessionTaskDelegate,NSURLSessionDownloadDelegate> {
    NSMutableArray *_networkSwitchD;

}

@end

@implementation DownloadManager

#pragma mark - Object lifecycle

- (id)init {
    if (self = [super init]) {
        self.downloadQueue = [[NSMutableArray alloc] init];
        [self createShareSession];

        //self.downloadwaitingQueue = [[NSMutableArray alloc] init];
        _networkSwitchD = [[NSMutableArray alloc] init];
        
        //_maxDownloadCount = [SettingConfig shareInstance].maxDownloadCount;//最大并发下载数
        [BaseFunc createFolderInDocument:[gAppRootPath stringByAppendingFormat:@"/%@",kDownloadInfoCacheSaveFolder]];

        //恢复之前的下载队列[包含下载中、下载失败、暂停、等待各种状态的oper](下载队列信息bm，不是某个下载的数据 与backgroundSessionConfig后台下载不冲突)
        [self resumeDownloadQueue];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeAA) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)applicationDidBecomeAA {
    NSLog(@"UIApplicationDidBecomeActive-------");

    //之前保存的队列信息中如果有正在执行的oper 则要恢复继续下载
    [self.lock lock];
    for (AppDownloadItemOperation *downloadItem in self.downloadQueue) {
        if (downloadItem.state == kDownloadItemOperationExecutingState) {
            if(nil != downloadItem.returnTask && downloadItem.returnTask.state == NSURLSessionTaskStateRunning) {
                continue;
            }
            downloadItem.fileSavePath = [gAppDownloadSavePath stringByAppendingPathComponent:downloadItem.uniqueID];
            [downloadItem continueOperation];
        }
    }
    [self.lock unlock];
}
    
#pragma mark - 创建共享session
- (void)createShareSession {
//    NSURLSessionConfiguration *configuration;
//    NSString *sessionIdentifier = @"com.avgPlatform.BackgroundSession";
//    if([UIDevice currentDevice].systemVersion.floatValue < 8.0) {
//        configuration = [NSURLSessionConfiguration backgroundSessionConfiguration:sessionIdentifier];
//    }else {
//        configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:sessionIdentifier];
//    }
//    //configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
//    configuration.discretionary = YES;
//    //configuration.timeoutIntervalForResource = 5;
//    //configuration.timeoutIntervalForRequest = 5;
//
//    self.sharedSession =  [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    
    self.sharedSessionForeground = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
    
    //应用被切到后台（用户去玩其他app、用户回到桌面、来电话）、应用正在使用突然闪退、应用被主动kill掉
}

#pragma mark - NSURLSessionDownloadDelegate回调
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    AppDownloadItemOperation *oper = [self getDownloadItemWithTaskIdentifier:dataTask.taskIdentifier];
    if (nil == oper) {
        NSLog(@"didReceiveResponse方法-- 没找到对应oper 直接返回");
        return;
    }
    
    oper.fileTotalSize = response.expectedContentLength;
    // 获得下载文件的总长度：请求下载的文件长度 + 当前已经下载的文件长度
    oper.fileTotalSize = response.expectedContentLength + oper.fileProgressSize;
    
    // 创建文件句柄
    oper.fileHandle = [NSFileHandle fileHandleForWritingAtPath:oper.fileSavePath];
    
    // 允许处理服务器的响应，才会继续接收服务器返回的数据
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    AppDownloadItemOperation *oper = [self getDownloadItemWithTaskIdentifier:dataTask.taskIdentifier];
    if (nil == oper) {
        NSLog(@"didReceiveResponse方法-- 没找到对应oper 直接返回");
        return;
    }
    // 指定数据的写入位置 -- 文件内容的最后面
    [oper.fileHandle seekToEndOfFile];
    
    // 向沙盒写入数据
    [oper.fileHandle writeData:data];
    
    // 拼接文件总长度
    oper.fileProgressSize += data.length;
    NSLog(@"这次获取到：%lu \n 当前已经下载：%lld \n 总共有多大：%lld",(unsigned long)data.length,oper.fileProgressSize,oper.fileTotalSize);
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval interval = now - oper.downloadStartTime;
    if (interval > 0.8) { //设置进度条计算的间隔为0.8秒以上,避免太频繁操作UI
        oper.downloadStartTime = now;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self responseOberserver:@selector(downloadProgress:) item:oper error:nil];
        });
    }
}
/////分割线

//- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
//    NSLog(@"Background URL session %@ finished events.\n", session);
//
//    if (session.configuration.identifier) {
//        // 调用在 -application:handleEventsForBackgroundURLSession: 中保存的 handler
//        if ([ConfigManager shareInstance].backgroundSessionCompletionHandler) {
//            NSLog(@"URLSessionDidFinishEventsForBackgroundURLSession------1111-------");
//            [ConfigManager shareInstance].backgroundSessionCompletionHandler();
//
//        }
//    }
//}

//- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
//    AppDownloadItemOperation *oper = [self getDownloadItemWithTaskIdentifier:downloadTask.taskIdentifier];
//    if (nil == oper) {
//        NSLog(@"URLSession--进度条方法-- 没找到对应oper 直接返回");
//        return;
//    }
//
//    //恢复下载队列时 如果oper里的task为nil 则需要重新指定好新对象
//    NSURLSessionDownloadTask *operInnerTask = [oper returnTask];
//    if (nil == operInnerTask) {
//        [oper setInTask:downloadTask];
//    }
//
//    oper.fileTotalSize = totalBytesExpectedToWrite;
//    oper.fileProgressSize = totalBytesWritten;
//
////    NSLog(@"_task ===== %@",operInnerTask);
//    NSLog(@"上一次已下载：%lld \n 这次获取到：%lld \n 当前已经下载：%lld \n 当前进度：%lld  \n  总共有多大：%lld",oper.lastDownloadFileProgressSize,bytesWritten,totalBytesWritten,oper.fileProgressSize,totalBytesExpectedToWrite);
//    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
//    NSTimeInterval interval = now - oper.downloadStartTime;
//    if (interval > 0.8) { //设置进度条计算的间隔为0.8秒以上,避免太频繁操作UI
//        oper.downloadStartTime = now;
//
//        dispatch_async(dispatch_get_main_queue(), ^{
//           [self responseOberserver:@selector(downloadProgress:) item:oper error:nil];
//        });
//    }
//}

//- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)downloadURL {
//    AppDownloadItemOperation *oper = [self getDownloadItemWithTaskIdentifier:downloadTask.taskIdentifier];
//    if (nil == oper) {
//        NSLog(@"URLSession--didFinishDownloadingToURL方法-- 没找到对应oper 直接返回");
//        return;
//    }
//
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    NSError *errorCopy;
//    NSLog(@"didFinishDownloadingToURL---------");
//    // For the purposes of testing, remove any esisting file at the destination.
//    //app崩溃后重启下载完成后 此时app的目录名称会改变，类似“xxxx-xxxx-xxx-xx”，所以不能用之前oper序列化里保存的filesavePath值
//    NSString *fileSavePath = [gAppDownloadSavePath stringByAppendingPathComponent:oper.url.lastPathComponent];
//    oper.fileSavePath = fileSavePath;
//    [fileManager removeItemAtPath:fileSavePath error:NULL];
//    BOOL success = [fileManager moveItemAtPath:downloadURL.relativePath toPath:fileSavePath error:&errorCopy];
//
//    if (success) {
//
//    } else {
//        NSLog(@"Error during the copy: %@", [errorCopy localizedDescription]);
//    }
//}
//
////每次在用上文中的ResumeData创建DownloadTask之后，然后让task开始执行，这个函数就会调用
//-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
////    AppDownloadItemOperation *oper = [self getDownloadItemWithTaskIdentifier:downloadTask.taskIdentifier];
////    if (nil == oper) {
////        NSLog(@"URLSession--didResumeAtOffset方法-- 没找到对应oper 直接返回");
////        return;
////    }
////    oper.lastDownloadFileProgressSize = fileOffset;
//    NSLog(@"9090------didResumeAtOffset = %lld --- expectedTotalBytes = %lld---",fileOffset,expectedTotalBytes);
//
//}

#pragma mark - Public func 添加一个下载

-(BOOL)addAppDownloadItem:(AppDownloadItemOperation *)item {
    BOOL addIsSuccess = NO;
    //先去除重复添加的下载
    AppDownloadItemOperation *oper = [self getDownloadItemWithAppID:item.uniqueID];
    if (oper) {
        return addIsSuccess;
    }
    
    if (nil!=item.url) {
        //下载任务刚添加到队列时就指定为等待状态
        item.state = kDownloadItemOperationWaitingState;
        
        [self.lock lock];
            [self.downloadQueue addObject:item];
        [self.lock unlock];
        
        if (![self isAttainMaxDownlodCount]) {
            [item startOperation:NO];
        }
        
        //添加一个下载时  就序列化当前下载对象信息
        [self archiverThisOper:item];
        
        //通知修改磁盘空间的 显示UI
//        [[NSNotificationCenter defaultCenter] postNotificationName:DiskSpaceDidChange object:nil userInfo:@{FileTotalSizeKey:@(item.fileTotalSize)}];
        
        addIsSuccess = YES;

        [self responseOberserver:@selector(downloadReady:) item:item error:nil];
    }
    return addIsSuccess;
}

#pragma mark - 真正取消某个下载
- (void)cancelDownloadItemWithAppId:(NSString *)appId {
    if (nil != appId) {
        AppDownloadItemOperation *downloadItem = [self getDownloadItemWithAppID:appId];
        if (nil != downloadItem) {
            DownloadItemOperationState sta = downloadItem.state;
            [downloadItem cancelOperation];
            [self.lock lock];
                [self.downloadQueue removeObject:downloadItem];
                [self removeArchiverThisOper:downloadItem];
            [self.lock unlock];
            if (kDownloadItemOperationExecutingState == sta) {
                [self stratNextReadyOperation];
            }
            
            [self noticeDownloadItemDidCancel:downloadItem];
        }
    }
}

- (void)cancelDownloadItemAtIndex:(int)index {
    AppDownloadItemOperation *downloadItem = nil;
    [self.lock lock];
    if (index >=0 && index < [self.downloadQueue count]) {
        downloadItem = [self.downloadQueue objectAtIndex:index];
        [downloadItem cancelOperation];
    }
    [self.lock unlock];
    if (nil != downloadItem) {
        [self.lock lock];
            [self.downloadQueue removeObjectAtIndex:index];
            [self removeArchiverThisOper:downloadItem];
        [self.lock unlock];
        [self stratNextReadyOperation];
        [self noticeDownloadItemDidCancel:downloadItem];
    }
    
}

- (void)cancelAllDownloadItem {
    for(AppDownloadItemOperation *downloadItem in self.downloadQueue) {
        [downloadItem cancelOperation];
        [self removeArchiverThisOper:downloadItem];
    }
    
    [self.lock lock];
    [self.downloadQueue removeAllObjects];
    [self.lock unlock];
    
    [self responseOberserver:@selector(downloadCancelAllDownload) item:nil error:nil];
}

#pragma mark - 开始下载
//- (void)startAllDownloadOperation {
//    NSInteger max = 3;//[SettingConfig shareInstance].maxDownloadCount;
//    while (max) {
//        BOOL isAttainMaxDownlodCount = [self isAttainMaxDownlodCount];
//        if (!isAttainMaxDownlodCount) { //没有达最大下载数
//            [self.lock lock];
//            for (AppDownloadItemOperation *downloadItem in self.downloadQueue) {
//                if (downloadItem.state==kDownloadItemOperationPausedState ||
//                    downloadItem.state==kDownloadItemOperationFaildState ||
//                    downloadItem.state==kDownloadItemOperationWaitingState) {//队列中是就绪状态的操作 开始
//                    [downloadItem startOperation];
//                    break;
//                }
//            }
//            [self.lock unlock];
//        }
//        max--;
//    }
//    [self responseOberserver:@selector(downloadReady:) item:nil error:nil];
//}

//- (void)startDownloadOperation:(NSString *)appId {
//    if (nil != appId) {
//        AppDownloadItemOperation *downloadItem = [self getDownloadItemWithAppID:appId];
//        BOOL isAttainMaxDownlodCount = [self isAttainMaxDownlodCount];
//        if (!isAttainMaxDownlodCount) {//没有达最大下载数，则开始，否则啥也不做
//            [downloadItem startOperation];
//        }
//
//        if (!isAttainMaxDownlodCount) {
//            [self responseOberserver:@selector(downloadResume:) item:downloadItem error:nil];
//        }
//    }
//}

//- (void)reStartDownloadOperation:(NSString *)appId {
//    if (nil != appId) {
//        AppDownloadItemOperation *downloadItem = [self getDownloadItemWithAppID:appId];
//        BOOL isAttainMaxDownlodCount = [self isAttainMaxDownlodCount];
//        if (!isAttainMaxDownlodCount) {//没有达最大下载数，则开始，否则啥也不做
//            [downloadItem reStartOperation];
//        }
//        
//        if (!isAttainMaxDownlodCount) {
//            [self responseOberserver:@selector(downloadResume:) item:downloadItem error:nil];
//        }
//    }
//}

- (void)continueDownloadOperation:(NSString *)appId {
    if (nil != appId) {
        BOOL isAttainMaxDownlodCount = [self isAttainMaxDownlodCount];
        if (!isAttainMaxDownlodCount) { //没有达最大下载数
            AppDownloadItemOperation *downloadItem = [self getDownloadItemWithAppID:appId];
            [downloadItem continueOperation];
        }
    }
}

#pragma mark - 暂停下载
- (void)pauseDownloadOperation:(NSString *)appId {
    if (nil != appId) {
        AppDownloadItemOperation *downloadItem = [self getDownloadItemWithAppID:appId];
        [downloadItem pauseOperation];
        
        [self stratNextReadyOperation];
        [self responseOberserver:@selector(downloadPause:) item:downloadItem error:nil];
    }
}



- (void)pauseAllDownloadOperation {//暂停所有，只要当前是下载中的才暂停
    [self.lock lock];
    for (AppDownloadItemOperation *item in self.downloadQueue) {
        if (kDownloadItemOperationExecutingState == item.state) {
            [item pauseOperation];
        }
    }
    [self.lock unlock];
    [self responseOberserver:@selector(downloadCancelAllDownload) item:nil error:nil];
}

- (void)pauseAllDownloadOperationBecauseNetwork {
    [self.lock lock];
    for(AppDownloadItemOperation *downloadItem in self.downloadQueue) {
        if (downloadItem.state == kDownloadItemOperationExecutingState) {
            [downloadItem pauseOperation];
            [_networkSwitchD addObject:downloadItem];
            [self responseOberserver:@selector(downloadPause:) item:downloadItem error:nil];
        }
    }
    [self.lock unlock];
}

#pragma mark - 下载队列总数
- (int)getDownloadingItemCount {
    int downloadItemCount = 0;
    [self.lock lock];
    downloadItemCount = (int)[self.downloadQueue count];
    [self.lock unlock];
    return downloadItemCount;
}

#pragma mark - 获取某个下载对象
- (AppDownloadItemOperation *)getDownloadItemAtIndex:(NSInteger)index {
    AppDownloadItemOperation *downloadItem = nil;
    [self.lock lock];
    if (index >=0 && index < [self.downloadQueue count]) {
        downloadItem = [self.downloadQueue objectAtIndex:index];
    }
    [self.lock unlock];
    return downloadItem;
}

- (AppDownloadItemOperation *)getDownloadItemWithAppID:(NSString *)appId {
    AppDownloadItemOperation *downloadItem = nil;
    if (nil != appId) {
        [self.lock lock];
        for (AppDownloadItemOperation *item in self.downloadQueue) {
            if ([item.uniqueID isEqualToString:appId]) {
                downloadItem = item;
                break;
            }
        }
        [self.lock unlock]; 
    }
    return downloadItem;
}

- (AppDownloadItemOperation *)getDownloadItemWithTaskIdentifier:(NSUInteger)identifier {
    AppDownloadItemOperation *downloadItem = nil;
    if (identifier) {
        [self.lock lock];
        for (AppDownloadItemOperation *item in self.downloadQueue) {
            //NSLog(@"item.taskIdentifier = %lu  identifier = %lu",(unsigned long)item.taskIdentifier,(unsigned long)identifier);
            if (item.taskIdentifier == identifier && item.state == kDownloadItemOperationExecutingState) {
                downloadItem = item;
                break;
            }
        }
        [self.lock unlock];
    }
    return downloadItem;
}

#pragma mark - 其他
- (BOOL)hasItemDownloading {
    BOOL isHas = NO;
    [self.lock lock];
    for (AppDownloadItemOperation *item in self.downloadQueue) {
        if (kDownloadItemOperationExecutingState == item.state) {
            isHas = YES;
            break;
        }
    }
    [self.lock unlock];
    return isHas;
}

- (int)downloadItemIndexOfObject:(AppDownloadItemOperation *)downloadItemOperation {
    int index = -1;
    if (nil != downloadItemOperation) {
        [self.lock lock];
        index = (int)[self.downloadQueue indexOfObject:downloadItemOperation];
        [self.lock unlock];
    }
    return index;
}

//序列化当前下载对象
- (void)archiverThisOper:(AppDownloadItemOperation *)item {
    if (nil != item) {
        NSData *downloadItemData = [NSKeyedArchiver archivedDataWithRootObject:item];
        if (nil != downloadItemData) {
            NSString *cacheItemSavePath = [gAppRootPath stringByAppendingFormat:@"/%@/%@.pp",kDownloadInfoCacheSaveFolder,item.uniqueID];
            if (![downloadItemData writeToFile:cacheItemSavePath atomically:YES]) {
                NSLog(@"新添加一个下载操作，将其写入缓存-写文件--失败！");
            }
        }
    }
}

//删除之前保存的系列化的对象信息--对应方法 archiverThisOper
- (void)removeArchiverThisOper:(AppDownloadItemOperation *)item {
    if (nil != item) {
        NSString *cacheItemSavePath = [gAppRootPath stringByAppendingFormat:@"/%@/%@.pp",kDownloadInfoCacheSaveFolder,item.uniqueID];
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:cacheItemSavePath error:&error];
        if (error) {
            NSLog(@"yi chu fakil!");
        }
    }
}

//开始下一个下载
- (void)stratNextReadyOperation {
    BOOL isAttainMaxDownlodCount = [self isAttainMaxDownlodCount];
    if (!isAttainMaxDownlodCount) { //没有达最大下载数
        [self.lock lock];
        for (AppDownloadItemOperation *downloadItem in self.downloadQueue) {
            if (downloadItem.state==kDownloadItemOperationWaitingState) {//队列中是就绪状态的操作 开始
                [downloadItem startOperation:NO];
                break;
            }
        }
        [self.lock unlock];
        
        //[self stratNextReadyOperation];
    }
}

#pragma mark - Private func
- (void)resumeDownloadQueue {
    NSString *cacheItemSavePath = [gAppRootPath stringByAppendingFormat:@"/%@",kDownloadInfoCacheSaveFolder];
    NSArray *tmplist = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:cacheItemSavePath error:nil];
    
    for (NSString *filename in tmplist) {
        if (![filename hasSuffix:@".pp"]) {
            continue;
        }
        
        NSString *fullpath = [cacheItemSavePath stringByAppendingPathComponent:filename];
        NSLog(@"恢复downloadQueue队列： %@",fullpath);
        NSData *downloadItemData = [NSData dataWithContentsOfFile:fullpath];
        if (nil != downloadItemData) {
            AppDownloadItemOperation *item = [NSKeyedUnarchiver unarchiveObjectWithData:downloadItemData];
            [self.downloadQueue addObject:item];
        }
        
    }
    
//    if(self.downloadQueue.count == 0){
//
//        [self clearTmpCache];
//    }
}

//- (void)clearTmpCache{
//    NSString *tmpDir = NSTemporaryDirectory();
//    NSArray *fileArr = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:tmpDir error:nil];
//    for (NSString *fileName in fileArr) {
//        NSString *filePath = [NSString stringWithFormat:@"%@%@",tmpDir,fileName];
//        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
//    }
//}

- (BOOL)isAttainMaxDownlodCount {
    int downloadingCount = 0;
    [self.lock lock];
    for (AppDownloadItemOperation *downloadItem in self.downloadQueue) {
        if (downloadItem.state == kDownloadItemOperationExecutingState) {
            downloadingCount += 1;
        }
    }
    [self.lock unlock];
    return (downloadingCount >= 3);//最多同时下载3个 其他为等待状态
}

- (void)noticeDownloadItemDidCancel:(AppDownloadItemOperation *)downloadItem {
    [self responseOberserver:@selector(downloadCancel) item:downloadItem error:nil];
}

@end
