#import <Foundation/Foundation.h>
#import <Virtualization/Virtualization.h>
#include <stdio.h>
#include <stdlib.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc < 3) {
            fprintf(stderr, "Usage: %s <kernel-path> <initramfs-path>\n", argv[0]);
            return 1;
        }

        NSString *kernelPath = [NSString stringWithUTF8String:argv[1]];
        NSString *initramfsPath = [NSString stringWithUTF8String:argv[2]];

        fprintf(stdout, "=== AVF Native Helper VM Boot ===\n");
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
        bootLoader.commandLine = @"console=hvc0";
        config.bootLoader = bootLoader;

        // Entropy device (Recommended for random number generation in Linux)
        VZVirtioEntropyDeviceConfiguration *entropy = [[VZVirtioEntropyDeviceConfiguration alloc] init];
        config.entropyDevices = @[entropy];

        // シリアルポート (標準出力を接続)
        NSFileHandle *stdoutHandle = [NSFileHandle fileHandleWithStandardOutput];
        NSFileHandle *stdinHandle = [NSFileHandle fileHandleWithStandardInput];
        VZFileHandleSerialPortAttachment *attachment = [[VZFileHandleSerialPortAttachment alloc] initWithFileHandleForReading:stdinHandle fileHandleForWriting:stdoutHandle];
        VZVirtioConsoleDeviceSerialPortConfiguration *serialConfig = [[VZVirtioConsoleDeviceSerialPortConfiguration alloc] init];
        serialConfig.attachment = attachment;
        config.serialPorts = @[serialConfig];

        NSError *error = nil;
        if (![config validateWithError:&error]) {
            fprintf(stderr, "Error: Configuration validation failed: %s\n", [[error localizedDescription] UTF8String]);
            return 1;
        }

        VZVirtualMachine *vm = [[VZVirtualMachine alloc] initWithConfiguration:config];

        fprintf(stdout, "Starting Virtual Machine...\n");
        [vm startWithCompletionHandler:^(NSError * _Nullable error) {
            if (error) {
                fprintf(stderr, "Error: VM startup failed: %s\n", [[error localizedDescription] UTF8String]);
                fprintf(stderr, "DebugDescription: %s\n", [[error debugDescription] UTF8String]);
                if ([error userInfo]) {
                    fprintf(stderr, "UserInfo: %s\n", [[[error userInfo] description] UTF8String]);
                }
                exit(1);
            } else {
                fprintf(stdout, "VM started successfully!\n");
                // 5秒後に停止するようにディスパッチ
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    fprintf(stdout, "Stopping VM...\n");
                    exit(0);
                });
            }
        }];

        dispatch_main();
    }
    return 0;
}
