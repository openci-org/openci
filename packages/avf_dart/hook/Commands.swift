import Foundation
import Virtualization


func runFetchIpswUrl(args: [String]) async {
    guard args.count >= 3 else {
        print("Usage: avf_helper fetch-ipsw-url <output-file>", to: &errStream)
        exit(1)
    }
    let outputPath = args[2]
    print("Fetching latest supported macOS IPSW restore image metadata from Apple...")
    fflush(stdout)

    do {
        let image = try await VZMacOSRestoreImage.latestSupported
        let urlStr = image.url.absoluteString
        try urlStr.write(toFile: outputPath, atomically: true, encoding: String.Encoding.utf8)
        print("Success: IPSW URL fetched and saved to \(outputPath)")
        exit(0)
    } catch {
        print("Error: Failed to fetch restore image metadata: \(error.localizedDescription)", to: &errStream)
        exit(1)
    }
}

func runInstall(args: [String]) async {
    guard args.count >= 6 else {
        print("Usage: avf_helper install <ipsw-path> <disk-img-path> <nvram-path> <config-json-path>", to: &errStream)
        exit(1)
    }
    let ipswPath = args[2]
    let diskImgPath = args[3]
    let nvramPath = args[4]
    let configJsonPath = args[5]

    print("=== macOS Installer Mode ===")
    print("IPSW: \(ipswPath)")
    print("Disk: \(diskImgPath)")
    print("NVRAM: \(nvramPath)")
    print("Config Output: \(configJsonPath)")
    fflush(stdout)

    let fileManager = FileManager.default

    if !fileManager.fileExists(atPath: ipswPath) {
        print("Error: IPSW file does not exist: \(ipswPath)", to: &errStream)
        exit(1)
    }

    if !fileManager.fileExists(atPath: diskImgPath) {
        print("Creating 64GB blank disk image at \(diskImgPath)...")
        fflush(stdout)
        let fd = open(diskImgPath, O_RDWR | O_CREAT, 0o666)
        if fd < 0 {
            print("Error: Failed to create disk image file: \(String(cString: strerror(errno)))", to: &errStream)
            exit(1)
        }
        if ftruncate(fd, off_t(64 * 1024 * 1024 * 1024)) != 0 {
            print("Error: Failed to set disk image size: \(String(cString: strerror(errno)))", to: &errStream)
            close(fd)
            exit(1)
        }
        close(fd)
    }

    let nvramDir = URL(fileURLWithPath: nvramPath).deletingLastPathComponent().path
    if !fileManager.fileExists(atPath: nvramDir) {
        try? fileManager.createDirectory(atPath: nvramDir, withIntermediateDirectories: true, attributes: nil)
    }

    guard VZVirtualMachine.isSupported else {
        print("Error: Virtualization is not supported on this host.", to: &errStream)
        exit(1)
    }

    print("Loading IPSW restore image...")
    fflush(stdout)
    let ipswURL = URL(fileURLWithPath: ipswPath)
    
    do {
        let restoreImage: VZMacOSRestoreImage = try await withCheckedThrowingContinuation { continuation in
            VZMacOSRestoreImage.load(from: ipswURL) { result in
                continuation.resume(with: result)
            }
        }

        guard let requirements = restoreImage.mostFeaturefulSupportedConfiguration else {
            print("Error: Failed to retrieve configuration requirements from restore image.", to: &errStream)
            exit(1)
        }

        let hardwareModel = requirements.hardwareModel
        let machineIdentifier = VZMacMachineIdentifier()

        let auxiliaryStorage = try VZMacAuxiliaryStorage(
            creatingStorageAt: URL(fileURLWithPath: nvramPath),
            hardwareModel: hardwareModel,
            options: []
        )

        let config = VZVirtualMachineConfiguration()
        config.cpuCount = max(4, requirements.minimumSupportedCPUCount)
        if config.cpuCount > VZVirtualMachineConfiguration.maximumAllowedCPUCount {
            config.cpuCount = VZVirtualMachineConfiguration.maximumAllowedCPUCount
        }

        config.memorySize = max(4 * 1024 * 1024 * 1024, requirements.minimumSupportedMemorySize)
        if config.memorySize > VZVirtualMachineConfiguration.maximumAllowedMemorySize {
            config.memorySize = VZVirtualMachineConfiguration.maximumAllowedMemorySize
        }

        let platform = VZMacPlatformConfiguration()
        platform.hardwareModel = hardwareModel
        platform.machineIdentifier = machineIdentifier
        platform.auxiliaryStorage = auxiliaryStorage
        config.platform = platform

        config.bootLoader = VZMacOSBootLoader()

        let attachment = try VZDiskImageStorageDeviceAttachment(url: URL(fileURLWithPath: diskImgPath), readOnly: false)
        let blockDevice = VZVirtioBlockDeviceConfiguration(attachment: attachment)
        config.storageDevices = [blockDevice]

        let networkAttachment = VZNATNetworkDeviceAttachment()
        let networkConfig = VZVirtioNetworkDeviceConfiguration()
        networkConfig.attachment = networkAttachment
        config.networkDevices = [networkConfig]

        let entropy = VZVirtioEntropyDeviceConfiguration()
        config.entropyDevices = [entropy]

        let graphics = VZMacGraphicsDeviceConfiguration()
        let display = VZMacGraphicsDisplayConfiguration(widthInPixels: 1024, heightInPixels: 768, pixelsPerInch: 80)
        graphics.displays = [display]
        config.graphicsDevices = [graphics]

        config.keyboards = [VZUSBKeyboardConfiguration()]
        config.pointingDevices = [VZUSBScreenCoordinatePointingDeviceConfiguration()]

        try config.validate()

        let vm = VZVirtualMachine(configuration: config)
        let installer = VZMacOSInstaller(virtualMachine: vm, restoringFromImageAt: ipswURL)

        let observation = installer.progress.observe(\.fractionCompleted, options: [.new]) { progress, change in
            let percent = (change.newValue ?? 0.0) * 100.0
            print(String(format: "Progress: %.2f%%", percent))
            fflush(stdout)
        }

        print("Starting macOS installation. This may take a while...")
        fflush(stdout)

        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                installer.install { result in
                    switch result {
                    case .success:
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        } catch {
            observation.invalidate()
            print("Error: Installation failed: \(error.localizedDescription)", to: &errStream)
            exit(1)
        }

        observation.invalidate()

        print("Installation completed successfully!")
        fflush(stdout)

        let hwB64 = hardwareModel.dataRepresentation.base64EncodedString()
        let machB64 = machineIdentifier.dataRepresentation.base64EncodedString()
        let jsonStr = """
        {
          "os": "macOS",
          "hardwareModel": "\(hwB64)",
          "machineIdentifier": "\(machB64)"
        }
        """

        try jsonStr.write(toFile: configJsonPath, atomically: true, encoding: String.Encoding.utf8)
        print("Configuration file successfully written to \(configJsonPath)")
        fflush(stdout)
        exit(0)

    } catch {
        print("Error: Installation failed: \(error.localizedDescription)", to: &errStream)
        exit(1)
    }
}

func runBoot(args: [String]) {
    guard args.count >= 7 else {
        print("Usage: avf_helper boot <disk-img-path> <nvram-path> <hardware-model-b64> <machine-identifier-b64> <mac-address>", to: &errStream)
        exit(1)
    }
    let diskImgPath = args[2]
    let nvramPath = args[3]
    let hardwareModelB64 = args[4]
    let machineIdentifierB64 = args[5]
    let macAddressStr = args[6]

    print("=== AVF Native Helper VM Boot (macOS Headless Mode) ===")
    print("Disk Image: \(diskImgPath)")
    print("NVRAM: \(nvramPath)")
    fflush(stdout)

    let fileManager = FileManager.default
    guard fileManager.fileExists(atPath: diskImgPath), fileManager.isReadableFile(atPath: diskImgPath) else {
        print("Error: Disk image file does not exist or is not readable: \(diskImgPath)", to: &errStream)
        exit(1)
    }
    guard fileManager.fileExists(atPath: nvramPath), fileManager.isReadableFile(atPath: nvramPath) else {
        print("Error: NVRAM file does not exist or is not readable: \(nvramPath)", to: &errStream)
        exit(1)
    }

    guard VZVirtualMachine.isSupported else {
        print("Error: Virtualization is not supported on this host.", to: &errStream)
        exit(1)
    }

    print("Allowed CPUs: \(VZVirtualMachineConfiguration.minimumAllowedCPUCount) - \(VZVirtualMachineConfiguration.maximumAllowedCPUCount)")
    print("Allowed Memory: \(VZVirtualMachineConfiguration.minimumAllowedMemorySize) - \(VZVirtualMachineConfiguration.maximumAllowedMemorySize) bytes")
    fflush(stdout)

    let config = VZVirtualMachineConfiguration()
    config.cpuCount = max(VZVirtualMachineConfiguration.minimumAllowedCPUCount, min(4, VZVirtualMachineConfiguration.maximumAllowedCPUCount))
    config.memorySize = max(VZVirtualMachineConfiguration.minimumAllowedMemorySize, min(4 * 1024 * 1024 * 1024, VZVirtualMachineConfiguration.maximumAllowedMemorySize))

    print("Configuring VM with \(config.cpuCount) CPUs and \(config.memorySize) bytes of memory")
    fflush(stdout)

    let platform = VZMacPlatformConfiguration()

    guard let hwData = Data(base64Encoded: hardwareModelB64),
          let hardwareModel = VZMacHardwareModel(dataRepresentation: hwData) else {
        print("Error: Invalid hardware model data representation.", to: &errStream)
        exit(1)
    }
    platform.hardwareModel = hardwareModel

    guard let machData = Data(base64Encoded: machineIdentifierB64),
          let machineIdentifier = VZMacMachineIdentifier(dataRepresentation: machData) else {
        print("Error: Invalid machine identifier data representation.", to: &errStream)
        exit(1)
    }
    platform.machineIdentifier = machineIdentifier

    platform.auxiliaryStorage = VZMacAuxiliaryStorage(contentsOf: URL(fileURLWithPath: nvramPath))
    config.platform = platform

    config.bootLoader = VZMacOSBootLoader()

    do {
        let attachment = try VZDiskImageStorageDeviceAttachment(url: URL(fileURLWithPath: diskImgPath), readOnly: false)
        let blockDevice = VZVirtioBlockDeviceConfiguration(attachment: attachment)
        config.storageDevices = [blockDevice]

        let networkAttachment = VZNATNetworkDeviceAttachment()
        let networkConfig = VZVirtioNetworkDeviceConfiguration()
        networkConfig.attachment = networkAttachment
        if let mac = VZMACAddress(string: macAddressStr) {
            networkConfig.macAddress = mac
        } else {
            print("Warning: Invalid MAC address format: \(macAddressStr). Using random MAC.", to: &errStream)
        }
        config.networkDevices = [networkConfig]

        let entropy = VZVirtioEntropyDeviceConfiguration()
        config.entropyDevices = [entropy]

        // Headless execution: no graphics, keyboard, pointing devices

        try config.validate()

        let vm = VZVirtualMachine(configuration: config)

        print("Starting Virtual Machine (Headless)...")
        fflush(stdout)

        vm.start { result in
            switch result {
            case .success:
                print("VM boot initiated. MAC address: \(macAddressStr)")
                print("Waiting for guest OS to allocate IP and start SSH...")
                fflush(stdout)
                
                Task {
                    var guestIp: String? = nil
                    let startTime = Date()
                    
                    // Loop until IP is allocated, timeout after 5 minutes
                    while guestIp == nil {
                        if Date().timeIntervalSince(startTime) > 300 {
                            fputs("Error: Timeout waiting for guest IP allocation.\n", stderr)
                            exit(1)
                        }
                        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                        guestIp = getIPAddress(forMac: macAddressStr)
                    }
                    
                    let ip = guestIp!
                    print("VM started successfully! IP: \(ip)")
                    fflush(stdout)
                }
                
            case .failure(let error):
                fputs("Error: VM startup failed: \(error.localizedDescription)\n", stderr)
                exit(1)
            }
        }

        // Keep process alive in headless mode
        dispatchMain()

    } catch {
        print("Error: Configuration validation failed: \(error.localizedDescription)", to: &errStream)
        exit(1)
    }
}
