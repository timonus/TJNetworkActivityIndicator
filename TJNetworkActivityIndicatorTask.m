//
//  TJNetworkActivityIndicatorTask.m
//  TJNetworkActivityIndicatorTask
//
//  Created by Tim Johnsen on 6/13/17.
//

#import "TJNetworkActivityIndicatorTask.h"

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <os/lock.h>

NSString *const TJNetworkActivityIndicatorStateChangeNotification = @"TJNetworkActivityIndicatorStateChangeNotification";
NSString *const TJNetworkActivityIndicatorStateKey = @"TJNetworkActivityIndicatorStateKey";

static char *const kTJNetworkActivityIndicatorTaskAdHocAssociatedObjectKey = "kTJNetworkActivityIndicatorTaskAdHocAssociatedObjectKey";

static NSInteger _networkTaskCount;
static NSMutableDictionary *_adHocTasks;
static dispatch_once_t _adHocTasksOnceToken;
static os_unfair_lock _adHocTasksLock;
static NSHashTable *_activeTasks;

#if defined(__has_attribute) && __has_attribute(objc_direct_members)
__attribute__((objc_direct_members))
#endif
@interface TJNetworkActivityIndicatorTask ()

@property (nonatomic, copy) NSString *taskDescription;
@property (nonatomic) BOOL hasEnded;

@end

#if defined(__has_attribute) && __has_attribute(objc_direct_members)
__attribute__((objc_direct_members))
#endif
@implementation TJNetworkActivityIndicatorTask

static void incrementNetworkTaskCount(const NSInteger increment)
{
    static os_unfair_lock lock = OS_UNFAIR_LOCK_INIT;
    os_unfair_lock_lock(&lock);
    
    const NSUInteger priorNetworkTaskCount = _networkTaskCount;
    _networkTaskCount += increment;
    
    NSCAssert(_networkTaskCount >= 0, @"Invalid network task count");
    const BOOL networkActivityIndicatorVisible = _networkTaskCount > 0;
    if (priorNetworkTaskCount > 0 != networkActivityIndicatorVisible) {
        if ([NSThread isMainThread]) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:networkActivityIndicatorVisible];
            [[NSNotificationCenter defaultCenter] postNotificationName:TJNetworkActivityIndicatorStateChangeNotification object:nil userInfo:@{TJNetworkActivityIndicatorStateKey: @(networkActivityIndicatorVisible)}];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:networkActivityIndicatorVisible];
                [[NSNotificationCenter defaultCenter] postNotificationName:TJNetworkActivityIndicatorStateChangeNotification object:nil userInfo:@{TJNetworkActivityIndicatorStateKey: @(networkActivityIndicatorVisible)}];
            });
        }
    }
    
    os_unfair_lock_unlock(&lock);
}

- (instancetype)init
{
    if (self = [super init]) {
        incrementNetworkTaskCount(1);
#if DEBUG
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _activeTasks = [NSHashTable weakObjectsHashTable];
        });
        [_activeTasks addObject:self];
#endif
    }
    return self;
}

- (instancetype)initWithTaskDescription:(nullable NSString *)taskDescription
{
    if (self = [self init]) {
        self.taskDescription = taskDescription;
    }
    return self;
}

- (void)endTask
{
    [self _endTaskWarnOnDuplicate:YES warnOnConfirmedEnd:NO];
}

- (void)_endTaskWarnOnDuplicate:(const BOOL)warnOnDuplicateEnd warnOnConfirmedEnd:(const BOOL)warnOnConfirmedEnd
{
    NSAssert(!warnOnDuplicateEnd || !self.hasEnded, @"Task ended twice.");
    if (!self.hasEnded) {
        incrementNetworkTaskCount(-1);
        self.hasEnded = YES;
        NSAssert(!warnOnConfirmedEnd, @"Task ended by deallocation");
    }
}

- (void)dealloc
{
    [self _endTaskWarnOnDuplicate:NO warnOnConfirmedEnd:YES];
}

- (NSString *)description
{
    return [[super description] stringByAppendingFormat:@" Task Description: %@", self.taskDescription];
}

+ (void)beginTaskWithIdentifier:(NSString *const)identifier
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _adHocTasks = [NSMutableDictionary new];
    });
    dispatch_once(&_adHocTasksOnceToken, ^{
        _adHocTasksLock = OS_UNFAIR_LOCK_INIT;
    });
    
    os_unfair_lock_lock(&_adHocTasksLock);
    TJNetworkActivityIndicatorTask *task = [_adHocTasks objectForKey:identifier];
    NSAssert(task == nil, @"Attempting to start ad hoc task with identifier %@ that's already been started.", identifier);
    if (!task) {
        task = [[TJNetworkActivityIndicatorTask alloc] initWithTaskDescription:identifier];
        [_adHocTasks setObject:task forKey:identifier];
    }
    os_unfair_lock_unlock(&_adHocTasksLock);
}

+ (void)endTaskWithIdentifier:(NSString *const)identifier
{
    TJNetworkActivityIndicatorTask *task = nil;
    dispatch_once(&_adHocTasksOnceToken, ^{
        _adHocTasksLock = OS_UNFAIR_LOCK_INIT;
    });
    os_unfair_lock_lock(&_adHocTasksLock);
    task = [_adHocTasks objectForKey:identifier];
    [_adHocTasks removeObjectForKey:identifier];
    os_unfair_lock_unlock(&_adHocTasksLock);
    NSAssert(task != nil, @"Attempting to end ad hoc task with identifier %@ that hasn't been started", identifier);
    [task endTask];
}

+ (void)beginTaskForObject:(const id)object
{
    TJNetworkActivityIndicatorTask *const task = objc_getAssociatedObject(object, kTJNetworkActivityIndicatorTaskAdHocAssociatedObjectKey);
    NSAssert(task, @"Attempting to start ad hoc task on object %@ that's already been started.", object);
    if (!task) {
        objc_setAssociatedObject(object, kTJNetworkActivityIndicatorTaskAdHocAssociatedObjectKey, [TJNetworkActivityIndicatorTask new], OBJC_ASSOCIATION_RETAIN);
    }
}

+ (void)endTaskForObject:(const id)object
{
    TJNetworkActivityIndicatorTask *const task = objc_getAssociatedObject(object, kTJNetworkActivityIndicatorTaskAdHocAssociatedObjectKey);
    NSAssert(!task, @"Attempting to end ad hoc task on object %@ that has no in progress task.", object);
    [task endTask];
    objc_setAssociatedObject(object, kTJNetworkActivityIndicatorTaskAdHocAssociatedObjectKey, nil, OBJC_ASSOCIATION_RETAIN);
}

@end
