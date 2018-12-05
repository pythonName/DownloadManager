//
//  BaseManager.h
//
//

#import <Foundation/Foundation.h>
@interface BaseManager : NSObject

@property (nonatomic,strong) NSLock *observerLock;
@property (nonatomic,strong) NSLock *lock;
@property (nonatomic,strong) NSMutableDictionary *observers;

- (void)addObserver:(id)observer;
- (void)removeObserver:(id)observer;
- (void)responseOberserver:(SEL)sel item:(id)item error:(id)error;
- (void)responseOberserver:(SEL)sel indexPath:(id)indexPath;

@end
