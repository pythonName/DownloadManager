//
//  AppDownloadManager.m
//

#import "AppDownloadManager.h"
#import "BaseFunc.h"
#import "NSURLSession+CorrectedResumeData.h"
//#import "IPAUtil.h"
//#import "FileHash.h"
//#import "VVGlobalDefine.h"

@interface AppDownloadManager()<UIAlertViewDelegate> {
    
    NSString *cacheDownloadWaitingSavePath;
    NSLock *_showReferLock;
    NSMutableDictionary *_originalDownloadUrls;
    AppDownloadItemOperation *_itemDownTemporary;
    NSString *_appleID;
    NSString *_countryStr;
    NSString *_appleIDPassword;
}

@end

@implementation AppDownloadManager

- (id)init {
    if (self = [super init]) {
        self.downloadingDiskSpace = 0.0;
        _showReferLock = [[NSLock alloc] init];
        _originalDownloadUrls = [[NSMutableDictionary alloc] init];

    }
    return self;
}

- (void)dealloc {
}

+ (AppDownloadManager *)sharedInstance {
    static AppDownloadManager *downloadManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloadManager = [[AppDownloadManager alloc] init];
        
    });
    return downloadManager;
}

- (void)cancelAllDownloadItem {
    [super cancelAllDownloadItem];//取消所有的下载
    self.downloadingDiskSpace = 0.0;//取消所有之后  记录下载队列中的统计变量要指为0；
}

#pragma mark 下载判断第一个调用的方法
-(BOOL)addAppDownloadItem:(AppDownloadItemOperation *)item {
    AppDownloadItemOperation *oper = (AppDownloadItemOperation *)item;
    
//    NSURL *url = [NSURL URLWithString:oper.url];
//    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
//    NSURLSession *session = [NSURLSession sharedSession];
//    [request setHTTPMethod:@"HEAD"];
//    NSURLSessionDataTask * dataTask =  [session dataTaskWithRequest:request completionHandler:^(NSData * __nullable data, NSURLResponse * __nullable response, NSError * __nullable error) {
//
//        //拿到响应头信息
//        NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
//
//        //4.解析拿到的响应数据
//        NSLog(@"%@\n%@",[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding],res.allHeaderFields);
//    }];
//    [dataTask resume];
    
//    //判断磁盘空间是否足够
//    self.downloadingDiskSpace = 0.0;//先指为0
//    for (AppDownloadItemOperation *operation in self.downloadQueue) {
//        self.downloadingDiskSpace += [self getCurrentDownloadOperSize:operation];
//    }
//    self.downloadingDiskSpace += [self getCurrentDownloadOperSize:oper];
//
//    if ([BaseFunc freeSpace]/1024.0/1024.0 - self.downloadingDiskSpace <= 300) {
//
//        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"存储空间不足！" preferredStyle:UIAlertControllerStyleAlert];
//        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil]];
//        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
//        return NO;
//    }
    
    return [super addAppDownloadItem:oper];

    return NO;
}

#pragma mark - NSURLSessionTaskDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    AppDownloadItemOperation *oper = [self getDownloadItemWithTaskIdentifier:task.taskIdentifier];
    if (nil == oper) {
        NSLog(@"URLSession--didCompleteWithError方法-- 没找到对应oper 直接返回");
        return;
    }
    
    //恢复下载队列时 如果oper里的task为nil 则需要重新指定好新对象
    NSURLSessionDataTask *operInnerTask = [oper returnTask];
    if (nil == operInnerTask) {
        [oper setInTask:(NSURLSessionDataTask *)task];
    }
    
    if (error == nil) {
        NSLog(@"Task: %@ completed successfully", task);
        oper.state = kDownloadItemOperationFinishedState;
        [oper.fileHandle closeFile];
        oper.fileHandle = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self handleDownloadCompletion:oper];
        });
    } else {
        NSLog(@"Task: %@ completed with error: %@", task, [error localizedDescription]);
        if ((NSURLErrorTimedOut == error.code || NSURLErrorNetworkConnectionLost == error.code) && self.isEnterBackground) {
            oper.state = kDownloadItemOperationExecutingState;
        }else {
            oper.state = kDownloadItemOperationFaildState;
        }
//        if ([[error localizedDescription] isEqualToString:@"cancelled"]) {
//            NSLog(@"调用task的cancelResumeData方法时出现此错误码");
//            oper.state = kDownloadItemOperationPausedState;
//        }else if(-999 == error.code){
//            NSLog(@"用户主动kill掉程序时 出现此错误码");
//            if ([error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData]) {
//                NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
//                NSLog(@"重新根据resumeData恢复下载--%@",resumeData);
////                NSURLSessionTask *task = [self.sharedSession downloadTaskWithResumeData:resumeData];
//                NSError *error;
//                NSPropertyListFormat format;
//                NSMutableDictionary *rr = (NSMutableDictionary *)[NSPropertyListSerialization propertyListWithData:resumeData options:NSPropertyListMutableContainersAndLeaves format:&format error:&error];
////
////                NSLog(@"rr = %@",rr);
////                NSURLRequest *originRequest = [NSKeyedUnarchiver unarchiveObjectWithData:[rr objectForKey:@"NSURLSessionResumeOriginalRequest"]];
////                NSLog(@"ori = %@",originRequest);
////                NSLog(@"ori header = %@",originRequest.allHTTPHeaderFields);
////
////                NSURLRequest *currentRequest = [NSKeyedUnarchiver unarchiveObjectWithData:[rr objectForKey:@"NSURLSessionResumeCurrentRequest"]];
////                NSLog(@"current = %@",currentRequest);
////                NSLog(@"current header = %@",currentRequest.allHTTPHeaderFields);
//                [rr removeObjectForKey:@"NSURLSessionResumeEntityTag"];//移除这个键值对，不然从头开始下载了 苹果的bug？
//                resumeData = [NSPropertyListSerialization
//                                    dataWithPropertyList:rr format:NSPropertyListXMLFormat_v1_0 options:0 error:nil];
//                NSURLSessionTask *task = [self.sharedSession downloadTaskWithResumeData:resumeData];
////                if (IS_IOS10ORLATER) {
////                    task = [self.sharedSession downloadTaskWithCorrectResumeData:resumeData];//这句会挂 有bug
////                } else {
////                    task = [self.sharedSession downloadTaskWithResumeData:resumeData];
////                }
//                [task resume];
//                oper.taskIdentifier = task.taskIdentifier;
//                oper.state = kDownloadItemOperationExecutingState;
//            }else {
//                oper.state = kDownloadItemOperationFaildState;
//            }
//        }else {
//            oper.state = kDownloadItemOperationFaildState;
//        }
        
        //下载对象状态信息变动 立马序列化
        [self archiverThisOper:oper];
        
        if(oper.state == kDownloadItemOperationFaildState) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self handleDownloadFailed:oper error:error];
            });
        }
    }
}

- (void)handleDownloadCompletion:(AppDownloadItemOperation *)downloadItem {
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)[downloadItem returnTask].response;
    NSInteger statusCode = response.statusCode;
    
    BOOL isSuccess = NO;
    AppDownloadItemOperation *oper = (AppDownloadItemOperation *)downloadItem;
    if(statusCode == 200 || [self isDownloadFinished:[downloadItem returnTask] task:downloadItem]) {
        NSLog(@"下载成功且包正确,");
        
        isSuccess = YES;
    } else if(!(statusCode == 206 || statusCode == 302)){
        NSLog(@"下载成功但包不正确-- statusCode = %ld response=%@  task = %@",(long)statusCode,response,[downloadItem returnTask]);
    }
    
    [self stratNextReadyOperation];
    
    if (isSuccess) {
        NSLog(@"下载成功且包没问题，通知各downloadCompletion委托");
        [self.lock lock];
            [self.downloadQueue removeObject:downloadItem];
            [self removeArchiverThisOper:downloadItem]; //序列化的downloadQueue信息对应要删掉
        [self.lock unlock];
        [self responseOberserver:@selector(downloadCompletion:) item:downloadItem error:nil];
    }else {
        NSLog(@"下载包有问题");
        //[[NSFileManager defaultManager] removeItemAtPath:downloadItem.fileSavePath error:nil];
        [self handleDownloadFailed:downloadItem error:[NSError errorWithDomain:@"AVGErrorDomain" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"下载包有问题"}]];
    }
}

- (void)handleDownloadFailed:(AppDownloadItemOperation *)downloadItem error:(NSError *)error {
    NSLog(@"下载失败");
    //AppDownloadItemOperation *oper = (AppDownloadItemOperation *)downloadItem;
    
    [super performSelector:@selector(stratNextReadyOperation) withObject:nil];
    
    [self responseOberserver:@selector(downloadFailed:error:) item:downloadItem error:error];
    
    if (nil == error) {
        //        [[RecordManager shareInstance] uploadDownloadStatus:oper msg:@"下载包有问题" code:1998 response:oper.returnOperation.response];
        return;
    }
}

#pragma mark - Private func
//- (CGFloat)getCurrentDownloadOperSize:(AppDownloadItemOperation *)oper {
//    NSString *appSize = oper.appInfo.appSize;
//    NSUInteger mbLength = [@"MB" length];
//    appSize = [appSize substringWithRange:NSMakeRange(0, appSize.length - mbLength)];
//    return [appSize floatValue];
//}

- (BOOL)isDownloadFinished:(NSURLSessionDataTask *)request task:(AppDownloadItemOperation *)task {
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)request.response;
    if(response.statusCode != 206) {
        return NO;
    }
    
//    // 先通过hash值判断下载是否成功
//    // hash不等 时通过文件大小
//    if([self localFileShaIsEqualTaskSha:task]) {
//        return YES;
//    }
    
    // 通过对比文件大小
    return [self localFileSizeEqualRequestSize:request task:task];
}

-(BOOL) localFileSizeEqualRequestSize:(NSURLSessionDataTask *)request task:(AppDownloadItemOperation *)task{
    // 再通过文件大小判断
    long long downloadedSize = [[BaseFunc getFileSize:task.fileSavePath] longLongValue];//self.downloadDestinationPath
    long long headSize = [self getSizeFormHead:request];
    if(downloadedSize >= headSize) {
        return YES;
    } else {
        return NO;
    }
}

-(long long )getSizeFormHead:(NSURLSessionDataTask *)request {
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)request.response;
    NSString *range = [response.allHeaderFields valueForKey:@"Content-Range"];
    if(range == nil) {
        return 0;
    }
    
    NSError *error=nil;
    NSRegularExpression *regex=nil;
    regex =  [NSRegularExpression regularExpressionWithPattern:@"bytes (\\d+)-(\\d+)/\\d+"
                                                       options:NSRegularExpressionCaseInsensitive
                                                         error:&error];
    
    NSTextCheckingResult *match = [regex firstMatchInString:range
                                                    options:NSMatchingAnchored
                                                      range:NSMakeRange(0, range.length)];
    
    unsigned long long  total = 0;
    if (match.numberOfRanges==3) {
        NSString *byteStr = [range substringWithRange:[match rangeAtIndex:1]];
        byteStr = [range substringWithRange:[match rangeAtIndex:2]];
        total = [byteStr longLongValue];
    }
    return total;
}


@end
