//
//  AppDownloadItemOperation.h
//

#import <Foundation/Foundation.h>
#import "DownloadItemOperation.h"
#import "AVGDetailInfo.h"
@interface AppDownloadItemOperation : DownloadItemOperation<NSCoding>

@property (nonatomic,strong) AVGGameChapterItem *chapter;
@property (nonatomic,strong) NSMutableDictionary *userInfo;

//- (NSMutableURLRequest *)getURLRequestWith:(NSString *)url fileSavePath:(NSString *)fileSavePath append:(BOOL)isAppend;

- (void)cancelOperation;

@end
