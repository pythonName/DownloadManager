//
//  AppDownloadItemOperation.m
//

#import "AppDownloadItemOperation.h"
#import "DownloadItemOperation.h"
#import "NSObject+Runtime.h"
#import "vvDefine.h"

@implementation AppDownloadItemOperation

- (void)encodeWithCoder:(NSCoder *)aCoder {
    NSDictionary *pros = [self properties_aps];
    //NSLog(@"[pros allKeys] = %@",[pros allKeys]);
    for(NSString *key in [pros allKeys]) {
//        if ([key isEqualToString:@"chapter"]) {
//            NSData *appData = [NSKeyedArchiver archivedDataWithRootObject:[pros objectForKey:key]];
//            [aCoder encodeObject:appData forKey:key];
//            continue;
//        }
        [aCoder encodeObject:[pros objectForKey:key] forKey:key];
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
 
        NSArray *arr = [self getAllProperties];
        for(NSString *key in arr) {
//            if ([key isEqualToString:@"chapter"]) {
//                id value = [aDecoder decodeObjectForKey:key];
//                _chapter = [NSKeyedUnarchiver unarchiveObjectWithData:value];
//                continue;
//            }
            id value = [aDecoder decodeObjectForKey:key];
            if (value)
                [self setValue:value forKey:key];
        }
    }

    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        
    }
    
    return self;
}

//- (NSMutableURLRequest *)getURLRequestWith:(NSString *)url fileSavePath:(NSString *)fileSavePath append:(BOOL)isAppend {
//    NSMutableURLRequest *request = [super getURLRequestWith:url fileSavePath:fileSavePath append:isAppend];
//    if (self.isDownloadFromAppStore) {
//        NSString *cookie = self.appstoreDownloadCookie;//[[NSUserDefaults standardUserDefaults] objectForKey:@"AppStroeDownloadCookie"];
//        [request setValue:@"iTunes/11.5.5 (Windows; Microsoft Windows 7 x64 Home Basic Edition Service Pack 1 (Build 7601)) AppleWebKit/536.30.1" forHTTPHeaderField:@"User-Agent"];
//        [request setValue:cookie forHTTPHeaderField:@"Cookie"];
//        [request setValue:@"identity" forHTTPHeaderField:@"Accept-Encoding"];
//        [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
//    }
//    
//    return request;
//}

//- (void)startOperation {
//    [super startOperation];
//    if (isExecuting) {
//        [self downloadUptoServer];
//    }
//}

#pragma mark - 取消下载状态上报 只针对正在下载的模块且要排除已经下载失败但还是留在界面上（downloadQueue）中得
- (void)cancelOperation {
//    if (self.state == kDownloadItemOperationExecutingState ||
//        self.state == kDownloadItemOperationPausedState) {
////        [[RecordManager shareInstance] uploadDownloadStatus:self msg:@"cancelDownload" code:-999 response:(NSHTTPURLResponse *)[self returnTask].response];
//    }
    [super cancelOperation];
}

#pragma mark - private
- (void)downloadUptoServer {
//    NSString *dType = RMDownloadType_Normal;
//   
//    if (!self.isReDownloadByProgram) {
//        //真正下载上报
//        NSDictionary *dic = @{RMAppID:getNoNilObject(self.appID),
//                              RMDownloadPage:getNoNilObject(self.downloadPage),
//                              RMDownloadType:getNoNilObject(dType),
//                              RMPosition:getNoNilObject([NSNumber numberWithInteger:self.cellPosition]),
//                              RMPath:getNoNilObject(self.path)};
//        
//        [RecordManager download:dic];
//        //下载次数统计 同上
//        NSDictionary *dicParam = @{@"url":getNoNilObject(self.url),@"appId":getNoNilObject(self.appID)};
//        [RecordManager recordRequestDownloadTimes:dicParam];
//    }
}

@end
