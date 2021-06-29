//
//  TJNetworkActivityIndicatorTask.h
//  TJNetworkActivityIndicatorTask
//
//  Created by Tim Johnsen on 6/13/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Notification posted whenever the global activity indicator's state changes. Always posted on the main thread.
extern NSNotificationName const TJNetworkActivityIndicatorStateChangeNotification;
/// Value is a BOOL indicating the global activity indicator's state.
extern NSString *const TJNetworkActivityIndicatorStateKey;

@interface TJNetworkActivityIndicatorTask : NSObject

/// Initialization implicitly begins a task.
/// Description is used for debugging.
- (instancetype)initWithTaskDescription:(nullable NSString *)taskDescription;
- (void)endTask;

+ (void)beginTaskWithIdentifier:(NSString *const)identifier;
+ (void)endTaskWithIdentifier:(NSString *const)identifier;

+ (void)beginTaskForObject:(const id)object;
+ (void)endTaskForObject:(const id)object;

@end

NS_ASSUME_NONNULL_END
