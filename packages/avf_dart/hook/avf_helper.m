#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <Virtualization/Virtualization.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>

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

NSData* dataFromBase64(NSString *base64Str) {
    return [[NSData alloc] initWithBase64EncodedString:base64Str options:0];
}

@interface InstallerObserver : NSObject
@property (strong) dispatch_semaphore_t semaphore;
@property (strong) NSError *error;
@end

@implementation InstallerObserver
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"fractionCompleted"]) {
        NSProgress *progress = (NSProgress *)object;
        fprintf(stdout, "Progress: %.2f%%\n", progress.fractionCompleted * 100.0);
        fflush(stdout);
    }
}
@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc < 2) {
            fprintf(stderr, "Usage: %s <subcommand> [args]\n", argv[0]);
            fprintf(stderr, "Subcommands:\n");
            fprintf(stderr, "  boot <disk-img-path> <nvram-path> <hardware-model-b64> <machine-identifier-b64>\n");
            fprintf(stderr, "  fetch-ipsw-url <output-file>\n");
            fprintf(stderr, "  install <ipsw-path> <disk-img-path> <nvram-path> <config-json-path>\n");
            return 1;
        }

        NSString *subcommand = [NSString stringWithUTF8String:argv[1]];

        if ([subcommand isEqualToString:@"fetch-ipsw-url"]) {
            if (argc < 3) {
                fprintf(stderr, "Usage: %s fetch-ipsw-url <output-file>\n", argv[0]);
                return 1;
            }
            NSString *outputPath = [NSString stringWithUTF8String:argv[2]];

            fprintf(stdout, "Fetching latest supported macOS IPSW restore image metadata from Apple...\n");
            fflush(stdout);

            dispatch_semaphore_t sem = dispatch_semaphore_create(0);
            __block NSString *urlStr = nil;
            __block NSError *fetchError = nil;

            [VZMacOSRestoreImage fetchLatestSupportedWithCompletionHandler:^(VZMacOSRestoreImage * _Nullable restoreImage, NSError * _Nullable error) {
                if (error) {
                    fetchError = error;
                } else if (restoreImage) {
                    urlStr = [restoreImage.URL absoluteString];
                }
                dispatch_semaphore_signal(sem);
            }];

            dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);

            if (fetchError) {
                fprintf(stderr, "Error: Failed to fetch restore image metadata: %s\n", [[fetchError localizedDescription] UTF8String]);
                return 1;
            }

            if (urlStr) {
                NSError *writeError = nil;
                [urlStr writeToFile:outputPath atomically:YES encoding:NSUTF8StringEncoding error:&writeError];
                if (writeError) {
                    fprintf(stderr, "Error: Failed to write URL to file: %s\n", [[writeError localizedDescription] UTF8String]);
                    return 1;
                }
                fprintf(stdout, "Success: IPSW URL fetched and saved to %s\n", [outputPath UTF8String]);
                return 0;
            } else {
                fprintf(stderr, "Error: No supported restore image found.\n");
                return 1;
            }
        }

        else if ([subcommand isEqualToString:@"install"]) {
            if (argc < 6) {
                fprintf(stderr, "Usage: %s install <ipsw-path> <disk-img-path> <nvram-path> <config-json-path>\n", argv[0]);
                return 1;
            }
            NSString *ipswPath = [NSString stringWithUTF8String:argv[2]];
            NSString *diskImgPath = [NSString stringWithUTF8String:argv[3]];
            NSString *nvramPath = [NSString stringWithUTF8String:argv[4]];
            NSString *configJsonPath = [NSString stringWithUTF8String:argv[5]];

            fprintf(stdout, "=== macOS Installer Mode ===\n");
            fprintf(stdout, "IPSW: %s\n", [ipswPath UTF8String]);
            fprintf(stdout, "Disk: %s\n", [diskImgPath UTF8String]);
            fprintf(stdout, "NVRAM: %s\n", [nvramPath UTF8String]);
            fprintf(stdout, "Config Output: %s\n", [configJsonPath UTF8String]);

            NSFileManager *fileManager = [NSFileManager defaultManager];
            
            // Check if IPSW exists
            if (![fileManager fileExistsAtPath:ipswPath]) {
                fprintf(stderr, "Error: IPSW file does not exist: %s\n", [ipswPath UTF8String]);
                return 1;
            }

            // Create blank disk.img if it does not exist
            if (![fileManager fileExistsAtPath:diskImgPath]) {
                fprintf(stdout, "Creating 64GB blank disk image at %s...\n", [diskImgPath UTF8String]);
                int fd = open([diskImgPath UTF8String], O_RDWR | O_CREAT, 0666);
                if (fd < 0) {
                    fprintf(stderr, "Error: Failed to create disk image file: %s\n", strerror(errno));
                    return 1;
                }
                if (ftruncate(fd, 64ULL * 1024 * 1024 * 1024) != 0) {
                    fprintf(stderr, "Error: Failed to set disk image size: %s\n", strerror(errno));
                    close(fd);
                    return 1;
                }
                close(fd);
            }

            // Ensure parent directory for NVRAM exists
            NSString *nvramDir = [nvramPath stringByDeletingLastPathComponent];
            if (![fileManager fileExistsAtPath:nvramDir]) {
                [fileManager createDirectoryAtPath:nvramDir withIntermediateDirectories:YES attributes:nil error:nil];
            }

            if (![VZVirtualMachine isSupported]) {
                fprintf(stderr, "Error: Virtualization is not supported on this host.\n");
                return 1;
            }

            // Load Restore Image
            NSURL *ipswURL = [NSURL fileURLWithPath:ipswPath];
            dispatch_semaphore_t sem = dispatch_semaphore_create(0);
            __block VZMacOSRestoreImage *restoreImage = nil;
            __block NSError *loadError = nil;

            fprintf(stdout, "Loading IPSW restore image...\n");
            [VZMacOSRestoreImage loadFileURL:ipswURL completionHandler:^(VZMacOSRestoreImage * _Nullable image, NSError * _Nullable error) {
                restoreImage = image;
                loadError = error;
                dispatch_semaphore_signal(sem);
            }];
            dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);

            if (loadError) {
                fprintf(stderr, "Error: Failed to load IPSW: %s\n", [[loadError localizedDescription] UTF8String]);
                return 1;
            }

            VZMacOSConfigurationRequirements *requirements = restoreImage.mostFeaturefulSupportedConfiguration;
            if (!requirements) {
                fprintf(stderr, "Error: Failed to retrieve configuration requirements from restore image.\n");
                return 1;
            }

            VZMacHardwareModel *hardwareModel = requirements.hardwareModel;
            VZMacMachineIdentifier *machineIdentifier = [[VZMacMachineIdentifier alloc] init];

            NSError *storageError = nil;
            VZMacAuxiliaryStorage *auxiliaryStorage = [[VZMacAuxiliaryStorage alloc] initCreatingStorageAtURL:[NSURL fileURLWithPath:nvramPath] hardwareModel:hardwareModel options:0 error:&storageError];
            if (storageError) {
                fprintf(stderr, "Error: Failed to create NVRAM storage: %s\n", [[storageError localizedDescription] UTF8String]);
                return 1;
            }

            VZVirtualMachineConfiguration *config = [[VZVirtualMachineConfiguration alloc] init];
            config.CPUCount = requirements.minimumSupportedCPUCount;
            if (config.CPUCount < 4) {
                config.CPUCount = 4; // macOS runs better with >= 4 CPUs
            }
            if (config.CPUCount > [VZVirtualMachineConfiguration maximumAllowedCPUCount]) {
                config.CPUCount = [VZVirtualMachineConfiguration maximumAllowedCPUCount];
            }

            config.memorySize = requirements.minimumSupportedMemorySize;
            if (config.memorySize < 4ULL * 1024 * 1024 * 1024) {
                config.memorySize = 4ULL * 1024 * 1024 * 1024; // macOS runs better with >= 4GB memory
            }
            if (config.memorySize > [VZVirtualMachineConfiguration maximumAllowedMemorySize]) {
                config.memorySize = [VZVirtualMachineConfiguration maximumAllowedMemorySize];
            }

            VZMacPlatformConfiguration *platform = [[VZMacPlatformConfiguration alloc] init];
            platform.hardwareModel = hardwareModel;
            platform.machineIdentifier = machineIdentifier;
            platform.auxiliaryStorage = auxiliaryStorage;
            config.platform = platform;

            config.bootLoader = [[VZMacOSBootLoader alloc] init];

            // Attach blank disk
            NSError *attachError = nil;
            VZDiskImageStorageDeviceAttachment *attachment = [[VZDiskImageStorageDeviceAttachment alloc] initWithURL:[NSURL fileURLWithPath:diskImgPath] readOnly:NO error:&attachError];
            if (attachError) {
                fprintf(stderr, "Error: Failed to attach disk: %s\n", [[attachError localizedDescription] UTF8String]);
                return 1;
            }
            VZVirtioBlockDeviceConfiguration *blockDevice = [[VZVirtioBlockDeviceConfiguration alloc] initWithAttachment:attachment];
            config.storageDevices = @[blockDevice];

            // NAT Network Configuration
            VZNATNetworkDeviceAttachment *networkAttachment = [[VZNATNetworkDeviceAttachment alloc] init];
            VZVirtioNetworkDeviceConfiguration *networkConfig = [[VZVirtioNetworkDeviceConfiguration alloc] init];
            networkConfig.attachment = networkAttachment;
            config.networkDevices = @[networkConfig];

            // Entropy device
            VZVirtioEntropyDeviceConfiguration *entropy = [[VZVirtioEntropyDeviceConfiguration alloc] init];
            config.entropyDevices = @[entropy];

            // Graphics configuration
            VZMacGraphicsDeviceConfiguration *graphics = [[VZMacGraphicsDeviceConfiguration alloc] init];
            VZMacGraphicsDisplayConfiguration *display = [[VZMacGraphicsDisplayConfiguration alloc] initWithWidthInPixels:1024 heightInPixels:768 pixelsPerInch:80];
            graphics.displays = @[display];
            config.graphicsDevices = @[graphics];

            // Keyboards and Pointing Devices
            config.keyboards = @[[[VZUSBKeyboardConfiguration alloc] init]];
            config.pointingDevices = @[[[VZUSBScreenCoordinatePointingDeviceConfiguration alloc] init]];

            NSError *validationError = nil;
            if (![config validateWithError:&validationError]) {
                fprintf(stderr, "Error: Configuration validation failed: %s\n", [[validationError localizedDescription] UTF8String]);
                return 1;
            }

            VZVirtualMachine *vm = [[VZVirtualMachine alloc] initWithConfiguration:config];
            VZMacOSInstaller *installer = [[VZMacOSInstaller alloc] initWithVirtualMachine:vm restoreImageURL:ipswURL];

            InstallerObserver *observer = [[InstallerObserver alloc] init];
            observer.semaphore = dispatch_semaphore_create(0);

            [installer.progress addObserver:observer forKeyPath:@"fractionCompleted" options:NSKeyValueObservingOptionNew context:nil];

            fprintf(stdout, "Starting macOS installation. This may take a while...\n");
            fflush(stdout);

            [installer installWithCompletionHandler:^(NSError * _Nullable error) {
                observer.error = error;
                dispatch_semaphore_signal(observer.semaphore);
            }];

            dispatch_semaphore_wait(observer.semaphore, DISPATCH_TIME_FOREVER);
            [installer.progress removeObserver:observer forKeyPath:@"fractionCompleted"];

            if (observer.error) {
                fprintf(stderr, "Error: Installation failed: %s\n", [[observer.error localizedDescription] UTF8String]);
                return 1;
            }

            fprintf(stdout, "Installation completed successfully!\n");

            // Write VM config.json
            NSString *hwB64 = [hardwareModel.dataRepresentation base64EncodedStringWithOptions:0];
            NSString *machB64 = [machineIdentifier.dataRepresentation base64EncodedStringWithOptions:0];
            NSString *jsonStr = [NSString stringWithFormat:@"{\n  \"os\": \"macOS\",\n  \"hardwareModel\": \"%@\",\n  \"machineIdentifier\": \"%@\"\n}\n", hwB64, machB64];

            NSError *writeError = nil;
            [jsonStr writeToFile:configJsonPath atomically:YES encoding:NSUTF8StringEncoding error:&writeError];
            if (writeError) {
                fprintf(stderr, "Error: Failed to write configuration JSON: %s\n", [[writeError localizedDescription] UTF8String]);
                return 1;
            }

            fprintf(stdout, "Configuration file successfully written to %s\n", [configJsonPath UTF8String]);
            return 0;
        }

        else if ([subcommand isEqualToString:@"boot"]) {
            if (argc < 6) {
                fprintf(stderr, "Usage: %s boot <disk-img-path> <nvram-path> <hardware-model-b64> <machine-identifier-b64>\n", argv[0]);
                return 1;
            }

            NSString *diskImgPath = [NSString stringWithUTF8String:argv[2]];
            NSString *nvramPath = [NSString stringWithUTF8String:argv[3]];
            NSString *hardwareModelB64 = [NSString stringWithUTF8String:argv[4]];
            NSString *machineIdentifierB64 = [NSString stringWithUTF8String:argv[5]];

            fprintf(stdout, "=== AVF Native Helper VM Boot (macOS Mode) ===\n");
            fprintf(stdout, "Disk Image: %s\n", [diskImgPath UTF8String]);
            fprintf(stdout, "NVRAM: %s\n", [nvramPath UTF8String]);

            // Check if files exist and are readable
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if (![fileManager fileExistsAtPath:diskImgPath]) {
                fprintf(stderr, "Error: Disk image file does not exist at path: %s\n", [diskImgPath UTF8String]);
                return 1;
            }
            if (![fileManager isReadableFileAtPath:diskImgPath]) {
                fprintf(stderr, "Error: Disk image file is not readable: %s\n", [diskImgPath UTF8String]);
                return 1;
            }
            if (![fileManager fileExistsAtPath:nvramPath]) {
                fprintf(stderr, "Error: NVRAM file does not exist at path: %s\n", [nvramPath UTF8String]);
                return 1;
            }
            if (![fileManager isReadableFileAtPath:nvramPath]) {
                fprintf(stderr, "Error: NVRAM file is not readable: %s\n", [nvramPath UTF8String]);
                return 1;
            }

            if (![VZVirtualMachine isSupported]) {
                fprintf(stderr, "Error: Virtualization is not supported on this host.\n");
                return 1;
            }

            fprintf(stdout, "Allowed CPUs: %lu - %lu\n", [VZVirtualMachineConfiguration minimumAllowedCPUCount], [VZVirtualMachineConfiguration maximumAllowedCPUCount]);
            fprintf(stdout, "Allowed Memory: %llu - %llu bytes\n", [VZVirtualMachineConfiguration minimumAllowedMemorySize], [VZVirtualMachineConfiguration maximumAllowedMemorySize]);

            VZVirtualMachineConfiguration *config = [[VZVirtualMachineConfiguration alloc] init];
            
            // Use 4 CPUs if allowed, else fallback to max allowed (macOS runs better with >= 4)
            NSUInteger cpuCount = 4;
            if (cpuCount > [VZVirtualMachineConfiguration maximumAllowedCPUCount]) {
                cpuCount = [VZVirtualMachineConfiguration maximumAllowedCPUCount];
            }
            if (cpuCount < [VZVirtualMachineConfiguration minimumAllowedCPUCount]) {
                cpuCount = [VZVirtualMachineConfiguration minimumAllowedCPUCount];
            }
            config.CPUCount = cpuCount;

            // Use 4GB memory if allowed, else fallback
            uint64_t memorySize = 4ULL * 1024 * 1024 * 1024; // 4GB
            if (memorySize > [VZVirtualMachineConfiguration maximumAllowedMemorySize]) {
                memorySize = [VZVirtualMachineConfiguration maximumAllowedMemorySize];
            }
            if (memorySize < [VZVirtualMachineConfiguration minimumAllowedMemorySize]) {
                memorySize = [VZVirtualMachineConfiguration minimumAllowedMemorySize];
            }
            config.memorySize = memorySize;

            fprintf(stdout, "Configuring VM with %lu CPUs and %llu bytes of memory\n", config.CPUCount, config.memorySize);

            // macOS Platform configuration
            VZMacPlatformConfiguration *platform = [[VZMacPlatformConfiguration alloc] init];

            NSData *hwModelData = dataFromBase64(hardwareModelB64);
            if (!hwModelData) {
                fprintf(stderr, "Error: Failed to decode hardware model base64.\n");
                return 1;
            }
            VZMacHardwareModel *hardwareModel = [[VZMacHardwareModel alloc] initWithDataRepresentation:hwModelData];
            if (!hardwareModel) {
                fprintf(stderr, "Error: Invalid hardware model data representation.\n");
                return 1;
            }
            platform.hardwareModel = hardwareModel;

            NSData *machIdData = dataFromBase64(machineIdentifierB64);
            if (!machIdData) {
                fprintf(stderr, "Error: Failed to decode machine identifier base64.\n");
                return 1;
            }
            VZMacMachineIdentifier *machineIdentifier = [[VZMacMachineIdentifier alloc] initWithDataRepresentation:machIdData];
            if (!machineIdentifier) {
                fprintf(stderr, "Error: Invalid machine identifier data representation.\n");
                return 1;
            }
            platform.machineIdentifier = machineIdentifier;

            VZMacAuxiliaryStorage *auxiliaryStorage = [[VZMacAuxiliaryStorage alloc] initWithURL:[NSURL fileURLWithPath:nvramPath]];
            platform.auxiliaryStorage = auxiliaryStorage;

            config.platform = platform;

            // Boot Loader
            VZMacOSBootLoader *bootLoader = [[VZMacOSBootLoader alloc] init];
            config.bootLoader = bootLoader;

            // Storage Device
            NSError *storageError = nil;
            VZDiskImageStorageDeviceAttachment *attachment = [[VZDiskImageStorageDeviceAttachment alloc] initWithURL:[NSURL fileURLWithPath:diskImgPath] readOnly:NO error:&storageError];
            if (storageError) {
                fprintf(stderr, "Error: Failed to create disk attachment: %s\n", [[storageError localizedDescription] UTF8String]);
                return 1;
            }
            VZVirtioBlockDeviceConfiguration *blockDevice = [[VZVirtioBlockDeviceConfiguration alloc] initWithAttachment:attachment];
            config.storageDevices = @[blockDevice];

            // Network Configuration (NAT for internet access in guest)
            VZNATNetworkDeviceAttachment *networkAttachment = [[VZNATNetworkDeviceAttachment alloc] init];
            VZVirtioNetworkDeviceConfiguration *networkConfig = [[VZVirtioNetworkDeviceConfiguration alloc] init];
            networkConfig.attachment = networkAttachment;
            config.networkDevices = @[networkConfig];

            // Entropy device
            VZVirtioEntropyDeviceConfiguration *entropy = [[VZVirtioEntropyDeviceConfiguration alloc] init];
            config.entropyDevices = @[entropy];

            // Graphics configuration (Required for Display)
            VZMacGraphicsDeviceConfiguration *graphics = [[VZMacGraphicsDeviceConfiguration alloc] init];
            VZMacGraphicsDisplayConfiguration *display = [[VZMacGraphicsDisplayConfiguration alloc] initWithWidthInPixels:1024 heightInPixels:768 pixelsPerInch:80];
            graphics.displays = @[display];
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

        else {
            fprintf(stderr, "Error: Unknown subcommand: %s\n", [subcommand UTF8String]);
            return 1;
        }
    }
    return 0;
}
