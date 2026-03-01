#include <dispatch/dispatch.h>
#include <CoreFoundation/CoreFoundation.h>
#include <Foundation/Foundation.h>

void ensure_main_queue_running(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            CFRunLoopRef mainRL = CFRunLoopGetMain();
            CFRunLoopPerformBlock(mainRL, kCFRunLoopCommonModes, ^{});
            CFRunLoopWakeUp(mainRL);
        });
    });
}

typedef void (^CompletionBlock)(void);

void run_on_main_queue_sync(CompletionBlock block) {
    if (pthread_main_np()) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

void run_on_main_queue_async(CompletionBlock block) {
    dispatch_async(dispatch_get_main_queue(), block);
}
