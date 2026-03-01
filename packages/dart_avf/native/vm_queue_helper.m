#import <Foundation/Foundation.h>
#import <Virtualization/Virtualization.h>
#import <dispatch/dispatch.h>
#import <stdio.h>

#if !__has_feature(objc_arc)
#error "This file must be compiled with ARC enabled"
#endif

static dispatch_queue_t _vm_queue = NULL;

dispatch_queue_t get_vm_queue(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _vm_queue = dispatch_queue_create("io.openci.vm", DISPATCH_QUEUE_SERIAL);
    });
    return _vm_queue;
}

VZVirtualMachine* create_vm_on_queue(VZVirtualMachineConfiguration* config) {
    __block VZVirtualMachine* vm = nil;
    dispatch_sync(get_vm_queue(), ^{
        vm = [[VZVirtualMachine alloc] initWithConfiguration:config queue:get_vm_queue()];
    });
    return vm;
}

int install_macos_sync(VZVirtualMachine* vm, const char* ipswPath) {
    __block int result = 0;
    __block BOOL done = NO;

    dispatch_semaphore_t sem = dispatch_semaphore_create(0);

    NSString* pathStr = [NSString stringWithUTF8String:ipswPath];
    NSString* resolvedPath = pathStr.stringByResolvingSymlinksInPath;
    NSURL* ipswURL = [NSURL fileURLWithPath:resolvedPath];

    fprintf(stderr, "   Resolved IPSW path: %s\n", resolvedPath.UTF8String);

    __block VZMacOSInstaller* installer = nil;
    __block NSProgress* progress = nil;

    dispatch_async(get_vm_queue(), ^{
        installer = [[VZMacOSInstaller alloc]
            initWithVirtualMachine:vm
            restoreImageURL:ipswURL];

        fprintf(stderr, "   Installer created, starting installation...\n");

        progress = installer.progress;

        [installer installWithCompletionHandler:^(NSError* error) {
            done = YES;
            fprintf(stderr, "\n");
            if (error) {
                fprintf(stderr, "❌ Install error [%s %ld]: %s\n",
                    error.domain.UTF8String,
                    (long)error.code,
                    error.localizedDescription.UTF8String);
                if (error.localizedFailureReason) {
                    fprintf(stderr, "   Reason: %s\n",
                        error.localizedFailureReason.UTF8String);
                }
                NSError* underlying = error.userInfo[NSUnderlyingErrorKey];
                while (underlying) {
                    fprintf(stderr, "   Caused by [%s %ld]: %s\n",
                        underlying.domain.UTF8String,
                        (long)underlying.code,
                        underlying.localizedDescription.UTF8String);
                    underlying = underlying.userInfo[NSUnderlyingErrorKey];
                }
                result = -1;
            } else {
                fprintf(stderr, "   Installation completed successfully!\n");
            }
            dispatch_semaphore_signal(sem);
        }];
    });

    while (!done) {
        sleep(10);
        if (progress) {
            double pct = progress.fractionCompleted * 100.0;
            fprintf(stderr, "\r   Progress: %.1f%%", pct);
            fflush(stderr);
        }
    }

    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    return result;
}

int start_vm_sync(VZVirtualMachine* vm) {
    __block int result = 0;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);

    dispatch_async(get_vm_queue(), ^{
        [vm startWithCompletionHandler:^(NSError* error) {
            if (error) {
                fprintf(stderr, "❌ Start error: %s\n",
                    error.localizedDescription.UTF8String);
                result = -1;
            }
            dispatch_semaphore_signal(sem);
        }];
    });

    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    return result;
}

int stop_vm_sync(VZVirtualMachine* vm) {
    __block int result = 0;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);

    dispatch_async(get_vm_queue(), ^{
        [vm stopWithCompletionHandler:^(NSError* error) {
            if (error) {
                fprintf(stderr, "❌ Stop error: %s\n",
                    error.localizedDescription.UTF8String);
                result = -1;
            }
            dispatch_semaphore_signal(sem);
        }];
    });

    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    return result;
}

void ensure_main_runloop(void) {
}
