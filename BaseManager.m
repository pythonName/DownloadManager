//
//  BaseManager.m
//

#import "BaseManager.h"
#import <objc/runtime.h>
#import <stdio.h>

@implementation BaseManager

- (id)init {
    if (self = [super init]) {
        self.observerLock = [[NSLock alloc] init];
        self.lock = [[NSLock alloc] init];
        self.observers = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (void)addObserver:(id)observer {
    if (nil != observer) {
        [_observerLock lock];//object_getClassName(observer)

        objc_setAssociatedObject(self,(__bridge const void *)(observer) , observer, OBJC_ASSOCIATION_ASSIGN);
        [_observers setObject: [NSValue valueWithPointer:(__bridge const void *)(observer)] forKey:[NSNumber numberWithLongLong:(long long)observer]];

        [_observerLock unlock];
    }
    else {
        NSLog(@"addObserver observer is nil");
    }
}

- (void)removeObserver:(id)observer {
    if (nil != observer) {
        [_observerLock lock];
        
        objc_setAssociatedObject(self, (__bridge const void *)(observer), nil, OBJC_ASSOCIATION_ASSIGN);
        [_observers removeObjectForKey:[NSNumber numberWithLongLong:(long long)observer]];
        
        [_observerLock unlock];
    }
    else {
        NSLog(@"removeObserver observer is nil");
    }
}

- (void)responseOberserver:(SEL)sel item:(id)item error:(id)error {
    [_observerLock lock];
    
    for (NSValue *observer in [_observers allValues]) {
        const void *p = [observer pointerValue];
        id obj = objc_getAssociatedObject(self, p);
        if (obj!=nil && [obj respondsToSelector:sel]) {
            //使用函数指针方式避免内存警告，详情:http://www.tuicool.com/articles/iu6zuu
//            IMP imp = [obj methodForSelector:sel];
//            void (*func)(id, SEL, id, id ) = (void *)imp;
//            func(obj, sel, item, error);
            [obj performSelector:sel withObject:item withObject:error];
        }
    }
    
    [_observerLock unlock];
}


@end
