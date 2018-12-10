//
//  DownloadItemOperationInfo.m
//  downloadTest
//
//  Created by apple on 12-8-18.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "DownloadItemOperation.h"
#import "BaseFunc.h"
#import "AppDownloadManager.h"

@interface  DownloadItemOperation(){
//    __block NSURLSessionDownloadTask *_task;
    __block NSURLSessionDataTask *_task;
}

@end

@implementation DownloadItemOperation

#pragma -
#pragma ObjectLifecycle

- (id)initWithUrl:(NSString *)url
        uniqueID:(NSString *)uniqueID{
    if (self = [super init]) {
        _url = [url copy];
        _uniqueID = [uniqueID copy];
        _fileSavePath = [gAppDownloadSavePath stringByAppendingPathComponent:uniqueID];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:_fileSavePath]) {
            // 如果下载文件路径已经存在，说明之前已经下载过，则指定断点下载
            _fileProgressSize = [[BaseFunc getFileSize:_fileSavePath] longLongValue];
        }else {
            // 如果没有下载文件的话，就创建一个空文件。如果有下载文件的话，则不用重新创建(不然会覆盖掉之前的文件)
            [[NSFileManager defaultManager] createFileAtPath:_fileSavePath contents:nil attributes:nil];
        }

        _fileTotalSize = 1;
    }
    return self;
}

- (void)dealloc {

}

- (NSURLSessionDataTask *)returnTask {
    return _task;
}

- (void)setInTask:(NSURLSessionDataTask *)task {
    _task = task;
}

- (void)setFileTotalSize:(long long)fileTotalSize {
    _fileTotalSize = fileTotalSize > 0 ? fileTotalSize : 1;
}

#pragma - mark 开始下载
- (void)startOperation:(BOOL)isBreakPointDownload {
    _downloadStartTime = [NSDate timeIntervalSinceReferenceDate];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.url]];
    request.timeoutInterval = 15.0;
    if (isBreakPointDownload) {
        // 设置HTTP请求头中的Range
        NSString *range = [NSString stringWithFormat:@"bytes=%lld-", _fileProgressSize];
        [request setValue:range forHTTPHeaderField:@"Range"];
        NSLog(@"从 %@ 开始", range);
    }
//    _task = [[AppDownloadManager sharedInstance].sharedSession downloadTaskWithRequest:request];
    _task = [[AppDownloadManager sharedInstance].sharedSessionForeground dataTaskWithRequest:request];
    [_task resume];
    
    self.taskIdentifier = _task.taskIdentifier;

    _state = kDownloadItemOperationExecutingState;
    //下载对象状态信息变动 立马序列化
    [[AppDownloadManager sharedInstance] archiverThisOper:self];
}

#pragma - mark 暂停下载
- (void)pauseOperation {
    if (NSURLSessionTaskStateRunning == _task.state) {
        [_task cancel];
        _state = kDownloadItemOperationPausedState;
    }
    
    //下载对象状态信息变动 立马序列化
    [[AppDownloadManager sharedInstance] archiverThisOper:self];
}

#pragma mark - 继续下载
- (void)continueOperation {
    _fileProgressSize = [[BaseFunc getFileSize:_fileSavePath] longLongValue];
    NSLog(@"%@ size: %lld", _fileSavePath, _fileProgressSize);
    [self startOperation:YES];

}

#pragma - mark 取消下载
- (void)cancelOperation {
    [_task cancel];//直接取消当前的下载任务
    //self.delegate = nil;

    _state = kDownloadItemOperationFinishedState;
}

//#pragma mark - private func
//- (void)cancelTaskResume {
//    [_task cancel];
////    __weak __typeof(self)weakSelf = self;
////    [_task cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
////        //在子线程该block
////        __strong __typeof(weakSelf) sSelf = weakSelf;
////        sSelf.resumeData = resumeData;
////    }];
//}

@end
