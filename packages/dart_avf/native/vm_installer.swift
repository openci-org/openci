import Foundation
import Virtualization
import AppKit

func discoverIP(mac: String, maxAttempts: Int = 12) {
    let normalizedMAC = mac.lowercased()
    for attempt in 1...maxAttempts {
        let pipe = Pipe()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/arp")
        process.arguments = ["-an"]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                for line in output.components(separatedBy: "\n") {
                    if line.lowercased().contains(normalizedMAC) {
                        if let ipMatch = line.range(of: #"\(([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)\)"#, options: .regularExpression) {
                            var ip = String(line[ipMatch])
                            ip = ip.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
                            fputs("\n🌐 VM IP: \(ip)\n", stderr)
                            fputs("   SSH:   ssh <user>@\(ip)\n\n", stderr)
                            return
                        }
                    }
                }
            }
        } catch {}
        if attempt < maxAttempts {
            Thread.sleep(forTimeInterval: 5)
        }
    }
    fputs("\n⚠️  Could not discover VM IP. Check 'arp -an' manually.\n", stderr)
}

class VMDelegate: NSObject, VZVirtualMachineDelegate {
    func virtualMachine(_ vm: VZVirtualMachine, didStopWithError error: Error) {
        fputs("❌ VM stopped with error: \(error.localizedDescription)\n", stderr)
    }
    func guestDidStop(_ vm: VZVirtualMachine) {
        fputs("ℹ️  Guest OS stopped\n", stderr)
    }
}

@MainActor
func createAndInstall(bundlePath: String, ipswPath: String, diskSizeGB: Int, cpuCount: Int, memoryGB: Int) async throws {
    fputs("🖥  OpenCI VM — Full Setup\n", stderr)
    fputs("   Bundle: \(bundlePath)\n", stderr)
    fputs("   IPSW:   \(ipswPath)\n", stderr)
    fputs("   Disk:   \(diskSizeGB)GB\n", stderr)
    fputs("   CPUs:   \(cpuCount)\n", stderr)
    fputs("   Memory: \(memoryGB)GB\n\n", stderr)

    let bundleURL = URL(fileURLWithPath: bundlePath)
    try FileManager.default.createDirectory(at: bundleURL, withIntermediateDirectories: true)

    fputs("[1/6] Loading restore image...\n", stderr)
    let ipswURL = URL(fileURLWithPath: ipswPath)
    let image = try await withCheckedThrowingContinuation { continuation in
        VZMacOSRestoreImage.load(from: ipswURL) { result in
            continuation.resume(with: result)
        }
    }

    guard let requirements = image.mostFeaturefulSupportedConfiguration else {
        throw NSError(domain: "VMHelper", code: 1, userInfo: [NSLocalizedDescriptionKey: "No supported configuration"])
    }

    let hardwareModel = requirements.hardwareModel
    guard hardwareModel.isSupported else {
        throw NSError(domain: "VMHelper", code: 2, userInfo: [NSLocalizedDescriptionKey: "Hardware model not supported"])
    }

    fputs("[2/6] Creating auxiliary storage...\n", stderr)
    let auxStorageURL = bundleURL.appendingPathComponent("AuxiliaryStorage")
    let auxStorage = try VZMacAuxiliaryStorage(creatingStorageAt: auxStorageURL, hardwareModel: hardwareModel)

    fputs("[3/6] Saving hardware model & machine ID...\n", stderr)
    let hwURL = bundleURL.appendingPathComponent("HardwareModel")
    try hardwareModel.dataRepresentation.write(to: hwURL)

    let machineIdentifier = VZMacMachineIdentifier()
    let midURL = bundleURL.appendingPathComponent("MachineIdentifier")
    try machineIdentifier.dataRepresentation.write(to: midURL)

    fputs("[4/6] Creating disk image (\(diskSizeGB)GB)...\n", stderr)
    let diskURL = bundleURL.appendingPathComponent("Disk.img")
    FileManager.default.createFile(atPath: diskURL.path, contents: nil)
    let fileHandle = try FileHandle(forWritingTo: diskURL)
    try fileHandle.truncate(atOffset: UInt64(diskSizeGB) * 1024 * 1024 * 1024)
    try fileHandle.close()

    fputs("[5/6] Building VM configuration...\n", stderr)
    let platform = VZMacPlatformConfiguration()
    platform.hardwareModel = hardwareModel
    platform.machineIdentifier = machineIdentifier
    platform.auxiliaryStorage = auxStorage

    let bootLoader = VZMacOSBootLoader()

    let diskAttachment = try VZDiskImageStorageDeviceAttachment(
        url: diskURL,
        readOnly: false,
        cachingMode: .automatic,
        synchronizationMode: .fsync
    )
    let storageDevice = VZVirtioBlockDeviceConfiguration(attachment: diskAttachment)

    let network = VZVirtioNetworkDeviceConfiguration()
    network.attachment = VZNATNetworkDeviceAttachment()
    let mac = VZMACAddress.randomLocallyAdministered()
    network.macAddress = mac
    try mac.string.write(to: bundleURL.appendingPathComponent("MACAddress"), atomically: true, encoding: .utf8)

    let config = VZVirtualMachineConfiguration()
    config.bootLoader = bootLoader
    config.platform = platform
    config.cpuCount = max(cpuCount, requirements.minimumSupportedCPUCount)
    config.memorySize = max(UInt64(memoryGB) * 1024 * 1024 * 1024, requirements.minimumSupportedMemorySize)
    config.storageDevices = [storageDevice]
    config.networkDevices = [network]
    config.entropyDevices = [VZVirtioEntropyDeviceConfiguration()]
    config.socketDevices = [VZVirtioSocketDeviceConfiguration()]

    let graphics = VZMacGraphicsDeviceConfiguration()
    graphics.displays = [VZMacGraphicsDisplayConfiguration(widthInPixels: 1920, heightInPixels: 1200, pixelsPerInch: 80)]
    config.graphicsDevices = [graphics]

    let sound = VZVirtioSoundDeviceConfiguration()
    sound.streams = [VZVirtioSoundDeviceOutputStreamConfiguration()]
    config.audioDevices = [sound]

    config.keyboards = [VZUSBKeyboardConfiguration()]
    config.pointingDevices = [VZUSBScreenCoordinatePointingDeviceConfiguration()]

    try config.validate()
    fputs("✅ VM configuration validated\n", stderr)

    let delegate = VMDelegate()
    let vm = VZVirtualMachine(configuration: config)
    vm.delegate = delegate

    fputs("[6/6] Installing macOS (this may take 20-60 minutes)...\n", stderr)
    let installer = VZMacOSInstaller(virtualMachine: vm, restoringFromImageAt: ipswURL)

    let progressObservation = installer.progress.observe(\.fractionCompleted) { progress, _ in
        let pct = progress.fractionCompleted * 100.0
        fputs("\r   Progress: \(String(format: "%.1f", pct))%", stderr)
        fflush(stderr)
    }

    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
        installer.install { result in
            continuation.resume(with: result)
        }
    }

    progressObservation.invalidate()
    _ = delegate
    fputs("\n✅ macOS VM created and installed successfully!\n", stderr)
    fputs("   Bundle: \(bundlePath)\n", stderr)
}

@MainActor
func installOnly(bundlePath: String, ipswPath: String, cpuCount: Int, memoryGB: Int) async throws {
    let hardwareModelData = try Data(contentsOf: URL(fileURLWithPath: "\(bundlePath)/HardwareModel"))
    guard let hardwareModel = VZMacHardwareModel(dataRepresentation: hardwareModelData) else {
        throw NSError(domain: "VMHelper", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create hardware model"])
    }
    let machineIdData = try Data(contentsOf: URL(fileURLWithPath: "\(bundlePath)/MachineIdentifier"))
    guard let machineIdentifier = VZMacMachineIdentifier(dataRepresentation: machineIdData) else {
        throw NSError(domain: "VMHelper", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to create machine identifier"])
    }
    let auxStorage = VZMacAuxiliaryStorage(contentsOf: URL(fileURLWithPath: "\(bundlePath)/AuxiliaryStorage"))

    let platform = VZMacPlatformConfiguration()
    platform.hardwareModel = hardwareModel
    platform.machineIdentifier = machineIdentifier
    platform.auxiliaryStorage = auxStorage

    let diskAttachment = try VZDiskImageStorageDeviceAttachment(
        url: URL(fileURLWithPath: "\(bundlePath)/Disk.img"), readOnly: false, cachingMode: .automatic, synchronizationMode: .fsync
    )
    let config = VZVirtualMachineConfiguration()
    config.bootLoader = VZMacOSBootLoader()
    config.platform = platform
    config.cpuCount = cpuCount
    config.memorySize = UInt64(memoryGB) * 1024 * 1024 * 1024
    config.storageDevices = [VZVirtioBlockDeviceConfiguration(attachment: diskAttachment)]
    let installNet = VZVirtioNetworkDeviceConfiguration()
    installNet.attachment = VZNATNetworkDeviceAttachment()
    let installMacFile = URL(fileURLWithPath: "\(bundlePath)/MACAddress")
    if let savedMAC = try? String(contentsOf: installMacFile, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines) {
        installNet.macAddress = VZMACAddress(string: savedMAC)!
    } else {
        let m = VZMACAddress.randomLocallyAdministered()
        installNet.macAddress = m
        try? m.string.write(to: installMacFile, atomically: true, encoding: .utf8)
    }
    config.networkDevices = [installNet]
    config.entropyDevices = [VZVirtioEntropyDeviceConfiguration()]
    config.socketDevices = [VZVirtioSocketDeviceConfiguration()]
    let g = VZMacGraphicsDeviceConfiguration()
    g.displays = [VZMacGraphicsDisplayConfiguration(widthInPixels: 1920, heightInPixels: 1200, pixelsPerInch: 80)]
    config.graphicsDevices = [g]
    config.audioDevices = [{ let s = VZVirtioSoundDeviceConfiguration(); s.streams = [VZVirtioSoundDeviceOutputStreamConfiguration()]; return s }()]
    config.keyboards = [VZUSBKeyboardConfiguration()]
    config.pointingDevices = [VZUSBScreenCoordinatePointingDeviceConfiguration()]
    try config.validate()
    fputs("✅ VM configuration validated\n", stderr)

    let delegate = VMDelegate()
    let vm = VZVirtualMachine(configuration: config)
    vm.delegate = delegate

    fputs("🔄 Installing macOS...\n", stderr)
    let installer = VZMacOSInstaller(virtualMachine: vm, restoringFromImageAt: URL(fileURLWithPath: ipswPath))
    let obs = installer.progress.observe(\.fractionCompleted) { p, _ in
        fputs("\r   Progress: \(String(format: "%.1f", p.fractionCompleted * 100))%", stderr)
        fflush(stderr)
    }
    try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
        installer.install { result in c.resume(with: result) }
    }
    obs.invalidate()
    _ = delegate
    fputs("\n✅ macOS installation completed!\n", stderr)
}

@MainActor
func startVM(bundlePath: String, cpuCount: Int, memoryGB: Int, gui: Bool) async throws {
    let hardwareModelData = try Data(contentsOf: URL(fileURLWithPath: "\(bundlePath)/HardwareModel"))
    guard let hardwareModel = VZMacHardwareModel(dataRepresentation: hardwareModelData) else {
        throw NSError(domain: "VMHelper", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create hardware model"])
    }
    let machineIdData = try Data(contentsOf: URL(fileURLWithPath: "\(bundlePath)/MachineIdentifier"))
    guard let machineIdentifier = VZMacMachineIdentifier(dataRepresentation: machineIdData) else {
        throw NSError(domain: "VMHelper", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to create machine identifier"])
    }
    let auxStorage = VZMacAuxiliaryStorage(contentsOf: URL(fileURLWithPath: "\(bundlePath)/AuxiliaryStorage"))

    let platform = VZMacPlatformConfiguration()
    platform.hardwareModel = hardwareModel
    platform.machineIdentifier = machineIdentifier
    platform.auxiliaryStorage = auxStorage

    let diskAttachment = try VZDiskImageStorageDeviceAttachment(
        url: URL(fileURLWithPath: "\(bundlePath)/Disk.img"), readOnly: false, cachingMode: .automatic, synchronizationMode: .fsync
    )
    let config = VZVirtualMachineConfiguration()
    config.bootLoader = VZMacOSBootLoader()
    config.platform = platform
    config.cpuCount = cpuCount
    config.memorySize = UInt64(memoryGB) * 1024 * 1024 * 1024
    config.storageDevices = [VZVirtioBlockDeviceConfiguration(attachment: diskAttachment)]

    let networkDev = VZVirtioNetworkDeviceConfiguration()
    networkDev.attachment = VZNATNetworkDeviceAttachment()
    let macFile = URL(fileURLWithPath: "\(bundlePath)/MACAddress")
    if let savedMAC = try? String(contentsOf: macFile, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines) {
        networkDev.macAddress = VZMACAddress(string: savedMAC)!
    } else {
        let mac = VZMACAddress.randomLocallyAdministered()
        networkDev.macAddress = mac
        try? mac.string.write(to: macFile, atomically: true, encoding: .utf8)
    }
    config.networkDevices = [networkDev]
    config.entropyDevices = [VZVirtioEntropyDeviceConfiguration()]
    config.socketDevices = [VZVirtioSocketDeviceConfiguration()]
    let g = VZMacGraphicsDeviceConfiguration()
    g.displays = [VZMacGraphicsDisplayConfiguration(widthInPixels: 1920, heightInPixels: 1200, pixelsPerInch: 80)]
    config.graphicsDevices = [g]
    let soundDev = VZVirtioSoundDeviceConfiguration()
    if gui {
        let inputStream = VZVirtioSoundDeviceInputStreamConfiguration()
        inputStream.source = VZHostAudioInputStreamSource()
        let outputStream = VZVirtioSoundDeviceOutputStreamConfiguration()
        outputStream.sink = VZHostAudioOutputStreamSink()
        soundDev.streams = [inputStream, outputStream]
    } else {
        soundDev.streams = [VZVirtioSoundDeviceOutputStreamConfiguration()]
    }
    config.audioDevices = [soundDev]
    if gui {
        config.keyboards = [VZMacKeyboardConfiguration()]
        config.pointingDevices = [VZMacTrackpadConfiguration()]
    } else {
        config.keyboards = [VZUSBKeyboardConfiguration()]
        config.pointingDevices = [VZUSBScreenCoordinatePointingDeviceConfiguration()]
    }
    try config.validate()
    fputs("✅ VM configuration validated\n", stderr)
    fputs("   MAC: \(networkDev.macAddress.string)\n", stderr)

    let delegate = VMDelegate()
    let vm = VZVirtualMachine(configuration: config)
    vm.delegate = delegate

    let macAddr = networkDev.macAddress.string
    DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
        discoverIP(mac: macAddr)
    }

    fputs("🔄 Starting VM...\n", stderr)

    if gui {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1280, height: 800),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "OpenCI VM — \(URL(fileURLWithPath: bundlePath).lastPathComponent)"
        window.center()

        let vmView = VZVirtualMachineView()
        vmView.virtualMachine = vm
        vmView.capturesSystemKeys = true
        vmView.automaticallyReconfiguresDisplay = true
        window.contentView = vmView
        window.makeKeyAndOrderFront(nil)

        let windowDelegate = VMWindowDelegate(vm: vm, delegate: delegate)
        window.delegate = windowDelegate

        vm.start { result in
            switch result {
            case .success:
                fputs("✅ VM started!\n", stderr)
            case .failure(let error):
                fputs("❌ VM start failed: \(error.localizedDescription)\n", stderr)
                exit(1)
            }
        }

        app.activate(ignoringOtherApps: true)
        app.run()
    } else {
        try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
            vm.start { result in c.resume(with: result) }
        }
        fputs("✅ VM started!\n", stderr)
        fputs("   Press Ctrl+C to stop\n", stderr)

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let s1 = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
            let s2 = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
            signal(SIGINT, SIG_IGN); signal(SIGTERM, SIG_IGN)
            s1.setEventHandler { s1.cancel(); s2.cancel(); continuation.resume() }
            s2.setEventHandler { s1.cancel(); s2.cancel(); continuation.resume() }
            s1.resume(); s2.resume()
        }

        try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
            vm.stop { error in
                if let error = error { c.resume(throwing: error) } else { c.resume() }
            }
        }
        _ = delegate
        fputs("✅ VM stopped.\n", stderr)
    }
}

class VMWindowDelegate: NSObject, NSWindowDelegate {
    let vm: VZVirtualMachine
    let vmDelegate: VMDelegate

    init(vm: VZVirtualMachine, delegate: VMDelegate) {
        self.vm = vm
        self.vmDelegate = delegate
    }

    func windowWillClose(_ notification: Notification) {
        fputs("🛑 Window closed, stopping VM...\n", stderr)
        if vm.state == .running || vm.state == .paused {
            vm.stop { error in
                if let error = error {
                    fputs("❌ Stop error: \(error.localizedDescription)\n", stderr)
                }
                fputs("✅ VM stopped.\n", stderr)
                exit(0)
            }
        } else {
            exit(0)
        }
    }
}

@main
struct VMHelper {
    static func main() async {
        guard CommandLine.arguments.count >= 3 else {
            fputs("Usage: vm_installer <command> <args...>\n", stderr)
            fputs("  setup    <bundle_path> <ipsw_path> [disk_gb] [cpu] [mem_gb]\n", stderr)
            fputs("  install  <bundle_path> <ipsw_path> [cpu] [mem_gb]\n", stderr)
            fputs("  start    <bundle_path> [cpu] [mem_gb]\n", stderr)
            exit(1)
        }

        let command = CommandLine.arguments[1]

        do {
            switch command {
            case "setup":
                guard CommandLine.arguments.count >= 4 else {
                    fputs("Usage: vm_installer setup <bundle_path> <ipsw_path> [disk_gb] [cpu] [mem_gb]\n", stderr)
                    exit(1)
                }
                let bundlePath = (CommandLine.arguments[2] as NSString).resolvingSymlinksInPath
                let ipswPath = (CommandLine.arguments[3] as NSString).resolvingSymlinksInPath
                let diskGB = CommandLine.arguments.count > 4 ? Int(CommandLine.arguments[4]) ?? 64 : 64
                let cpuCount = CommandLine.arguments.count > 5 ? Int(CommandLine.arguments[5]) ?? 4 : 4
                let memoryGB = CommandLine.arguments.count > 6 ? Int(CommandLine.arguments[6]) ?? 8 : 8
                try await createAndInstall(bundlePath: bundlePath, ipswPath: ipswPath, diskSizeGB: diskGB, cpuCount: cpuCount, memoryGB: memoryGB)
            case "install":
                guard CommandLine.arguments.count >= 4 else {
                    fputs("Usage: vm_installer install <bundle_path> <ipsw_path> [cpu] [mem_gb]\n", stderr)
                    exit(1)
                }
                let bundlePath = (CommandLine.arguments[2] as NSString).resolvingSymlinksInPath
                let ipswPath = (CommandLine.arguments[3] as NSString).resolvingSymlinksInPath
                let cpuCount = CommandLine.arguments.count > 4 ? Int(CommandLine.arguments[4]) ?? 4 : 4
                let memoryGB = CommandLine.arguments.count > 5 ? Int(CommandLine.arguments[5]) ?? 8 : 8
                try await installOnly(bundlePath: bundlePath, ipswPath: ipswPath, cpuCount: cpuCount, memoryGB: memoryGB)
            case "start":
                let args = Array(CommandLine.arguments.dropFirst(2))
                let gui = args.contains("--gui")
                let positionalArgs = args.filter { !$0.hasPrefix("--") }
                let bundlePath = (positionalArgs[0] as NSString).resolvingSymlinksInPath
                let cpuCount = positionalArgs.count > 1 ? Int(positionalArgs[1]) ?? 4 : 4
                let memoryGB = positionalArgs.count > 2 ? Int(positionalArgs[2]) ?? 8 : 8
                try await startVM(bundlePath: bundlePath, cpuCount: cpuCount, memoryGB: memoryGB, gui: gui)
            default:
                fputs("❌ Unknown command: \(command)\n", stderr)
                exit(1)
            }
        } catch let error as NSError {
            fputs("\n❌ Error: \(error.localizedDescription)\n", stderr)
            if let reason = error.localizedFailureReason {
                fputs("   Reason: \(reason)\n", stderr)
            }
            var underlying = error.userInfo[NSUnderlyingErrorKey] as? NSError
            while let u = underlying {
                fputs("   Caused by [\(u.domain) \(u.code)]: \(u.localizedDescription)\n", stderr)
                underlying = u.userInfo[NSUnderlyingErrorKey] as? NSError
            }
            fputs("   Full error: \(error)\n", stderr)
            exit(1)
        } catch {
            fputs("\n❌ Error: \(error)\n", stderr)
            exit(1)
        }
    }
}
