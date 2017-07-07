//
//  TJNetworkActivityIndicatorTask.m
//  TJNetworkActivityIndicatorTask
//
//  Created by Tim Johnsen on 6/13/17.
//

#import "TJNetworkActivityIndicatorTask.h"

#import "UIApplication+Opener.h"
#import <objc/runtime.h>
#import <os/lock.h>

NSString *const TJNetworkActivityIndicatorStateChangeNotification = @"tj.nic";
NSString *const TJNetworkActivityIndicatorStateKey = @"tj.nic.s";

static NSInteger _networkTaskCount;
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
            [[UIApplication open_sharedApplication] setNetworkActivityIndicatorVisible:networkActivityIndicatorVisible];
            [[NSNotificationCenter defaultCenter] postNotificationName:TJNetworkActivityIndicatorStateChangeNotification object:nil userInfo:@{TJNetworkActivityIndicatorStateKey: @(networkActivityIndicatorVisible)}];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication open_sharedApplication] setNetworkActivityIndicatorVisible:networkActivityIndicatorVisible];
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

@end
