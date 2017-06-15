# TJNetworkActivityIndicatorTask

*This hasn't been shipped in a production app yet and should be considered incomplete*

A manager for your iOS app's network activity indicator.

## Catches common issues
- Warns if a task is ended multiple times.
- Warns if a task is started multiple times (and makes it harder to do so).
- Threadsafe and dispatches changes to `UIApplication`'s network indicator to main thread correctly.

## Usage

Preferred

```
TJNetworkActivityIndicatorTask *const task = [TJNetworkActivityIndicatorTask new];
doThingOnNetworkWithCompletion(^ {
    [task endTask];
});
```

Discouraged, but provided for completeness

```
// Somewhere in your codebase.
[TJNetworkActivityIndicatorTask beginTaskWithIdentifier:@"foo"];

// Somewhere completely disconnected from -begin... call in your codebase.
[TJNetworkActivityIndicatorTask endTaskWithIdentifier:@"foo"];
```

## To be done
- Introduce warning if task takes longer than expected.
- Capture backtraces when tasks are started in debug builds to provide more context.
- Add convenience methods for managing tasks via associated objects.
