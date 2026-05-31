#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <Virtualization/Virtualization.h>
#include <stdio.h>
#include <stdlib.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate>
@property (strong) NSWindow *window;
@property (strong) VZVirtualMachine *vm;
@property (strong) VZVirtualMachineView *vmView;
@end

@implementation AppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    // Create UI Window
    NSRect frame = NSMakeRect(0, 0, 1024, 768);
    self.window = [[NSWindow alloc] initWithContentRect:frame
                                              styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable)
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];
    self.window.title = @"Apple Virtualization Framework VM";
    self.window.delegate = self;
    
    // Create Virtual Machine View
    self.vmView = [[VZVirtualMachineView alloc] initWithFrame:frame];
    self.vmView.virtualMachine = self.vm;
    self.vmView.capturesSystemKeys = YES;
    
    self.window.contentView = self.vmView;
    [self.window makeKeyAndOrderFront:nil];
    
    // Make sure window pops up to the front
    [NSApp activateIgnoringOtherApps:YES];
    
    fprintf(stdout, "Starting Virtual Machine...\n");
    [self.vm startWithCompletionHandler:^(NSError * _Nullable error) {
        if (error) {
            fprintf(stderr, "Error: VM startup failed: %s\n", [[error localizedDescription] UTF8String]);
            exit(1);
        } else {
            fprintf(stdout, "VM started successfully!\n");
        }
    }];
}

- (void)windowWillClose:(NSNotification *)notification {
    fprintf(stdout, "Window closing. Stopping VM...\n");
    [self.vm stopWithCompletionHandler:^(NSError * _Nullable error) {
        exit(0);
    }];
}
@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc < 3) {
            fprintf(stderr, "Usage: %s <kernel-path> <initramfs-path>\n", argv[0]);
            return 1;
        }

        NSString *kernelPath = [NSString stringWithUTF8String:argv[1]];
        NSString *initramfsPath = [NSString stringWithUTF8String:argv[2]];

        fprintf(stdout, "=== AVF Native Helper VM Boot (GUI Mode) ===\n");
        fprintf(stdout, "Kernel: %s\n", [kernelPath UTF8String]);
        fprintf(stdout, "Initramfs: %s\n", [initramfsPath UTF8String]);

        // Check if files exist and are readable
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:kernelPath]) {
            fprintf(stderr, "Error: Kernel file does not exist at path: %s\n", [kernelPath UTF8String]);
            return 1;
        }
        if (![fileManager isReadableFileAtPath:kernelPath]) {
            fprintf(stderr, "Error: Kernel file is not readable: %s\n", [kernelPath UTF8String]);
            return 1;
        }
        if (![fileManager fileExistsAtPath:initramfsPath]) {
            fprintf(stderr, "Error: Initramfs file does not exist at path: %s\n", [initramfsPath UTF8String]);
            return 1;
        }
        if (![fileManager isReadableFileAtPath:initramfsPath]) {
            fprintf(stderr, "Error: Initramfs file is not readable: %s\n", [initramfsPath UTF8String]);
            return 1;
        }

        if (![VZVirtualMachine isSupported]) {
            fprintf(stderr, "Error: Virtualization is not supported on this host.\n");
            return 1;
        }

        fprintf(stdout, "Allowed CPUs: %lu - %lu\n", [VZVirtualMachineConfiguration minimumAllowedCPUCount], [VZVirtualMachineConfiguration maximumAllowedCPUCount]);
        fprintf(stdout, "Allowed Memory: %llu - %llu bytes\n", [VZVirtualMachineConfiguration minimumAllowedMemorySize], [VZVirtualMachineConfiguration maximumAllowedMemorySize]);

        VZVirtualMachineConfiguration *config = [[VZVirtualMachineConfiguration alloc] init];
        config.CPUCount = 2;
        config.memorySize = 1024 * 1024 * 1024; // 1GB

        // Platform configuration (Required for Linux guests)
        VZGenericPlatformConfiguration *platform = [[VZGenericPlatformConfiguration alloc] init];
        VZGenericMachineIdentifier *machineIdentifier = [[VZGenericMachineIdentifier alloc] init];
        platform.machineIdentifier = machineIdentifier;
        config.platform = platform;

        VZLinuxBootLoader *bootLoader = [[VZLinuxBootLoader alloc] initWithKernelURL:[NSURL fileURLWithPath:kernelPath]];
        bootLoader.initialRamdiskURL = [NSURL fileURLWithPath:initramfsPath];
        // console=tty0 outputs boot screen graphics
        bootLoader.commandLine = @"console=hvc0 console=tty0";
        config.bootLoader = bootLoader;

        // Entropy device
        VZVirtioEntropyDeviceConfiguration *entropy = [[VZVirtioEntropyDeviceConfiguration alloc] init];
        config.entropyDevices = @[entropy];

        // Serial Port (Attach standard I/O for fallback CLI access)
        NSFileHandle *stdoutHandle = [NSFileHandle fileHandleWithStandardOutput];
        NSFileHandle *stdinHandle = [NSFileHandle fileHandleWithStandardInput];
        VZFileHandleSerialPortAttachment *attachment = [[VZFileHandleSerialPortAttachment alloc] initWithFileHandleForReading:stdinHandle fileHandleForWriting:stdoutHandle];
        VZVirtioConsoleDeviceSerialPortConfiguration *serialConfig = [[VZVirtioConsoleDeviceSerialPortConfiguration alloc] init];
        serialConfig.attachment = attachment;
        config.serialPorts = @[serialConfig];

        // Graphics configuration (Required for Display)
        VZVirtioGraphicsDeviceConfiguration *graphics = [[VZVirtioGraphicsDeviceConfiguration alloc] init];
        VZVirtioGraphicsScanoutConfiguration *scanout = [[VZVirtioGraphicsScanoutConfiguration alloc] initWithWidthInPixels:1024 heightInPixels:768];
        graphics.scanouts = @[scanout];
        config.graphicsDevices = @[graphics];

        // Keyboards and Pointing Devices (Required for VM user input)
        config.keyboards = @[[[VZUSBKeyboardConfiguration alloc] init]];
        config.pointingDevices = @[[[VZUSBScreenCoordinatePointingDeviceConfiguration alloc] init]];

        NSError *error = nil;
        if (![config validateWithError:&error]) {
            fprintf(stderr, "Error: Configuration validation failed: %s\n", [[error localizedDescription] UTF8String]);
            return 1;
        }

        VZVirtualMachine *vm = [[VZVirtualMachine alloc] initWithConfiguration:config];

        // Start Cocoa event loop
        NSApplication *app = [NSApplication sharedApplication];
        [app setActivationPolicy:NSApplicationActivationPolicyRegular];
        
        AppDelegate *delegate = [[AppDelegate alloc] init];
        delegate.vm = vm;
        app.delegate = delegate;
        
        [app run];
    }
    return 0;
}
