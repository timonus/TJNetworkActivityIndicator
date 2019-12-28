# TJNetworkActivityIndicatorTask

A manager for your iOS app's network activity indicator.

## Catches common issues
- Warns if a task is ended multiple times.
- Warns if a task is started multiple times and makes it much harder to do so.
- Threadsafe and dispatches changes to `UIApplication`'s network indicator on main thread correctly.

## Usage

Preferred method:

```objc
TJNetworkActivityIndicatorTask *const task = [TJNetworkActivityIndicatorTask new];
doThingOnNetworkWithCompletion(^ {
    [task endTask];
});
```

Less preferred, but provided for simplicity:

```objc
[TJNetworkActivityIndicatorTask beginTaskForObject:myObject];
// Later on
[TJNetworkActivityIndicatorTask endTaskForObject:myObject];
```

Discouraged, but provided for completeness:

```objc
// Somewhere in your codebase.
[TJNetworkActivityIndicatorTask beginTaskWithIdentifier:@"foo"];

// Somewhere completely disconnected from -begin... call in your codebase.
[TJNetworkActivityIndicatorTask endTaskWithIdentifier:@"foo"];
```

## To be done
- Introduce warning if task takes longer than expected.
- Capture backtraces when tasks are started in debug builds to provide more context.
