import Foundation
import AppKit
import Virtualization

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var window: NSWindow!
    var vm: VZVirtualMachine!
    var vmView: VZVirtualMachineView!
    var macAddress: String?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let frame = NSRect(x: 0, y: 0, width: 1024, height: 768)
        window = NSWindow(
            contentRect: frame,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Apple Virtualization Framework VM"
        window.delegate = self

        vmView = VZVirtualMachineView(frame: frame)
        vmView.virtualMachine = vm
        vmView.capturesSystemKeys = true

        window.contentView = vmView
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        print("Starting Virtual Machine...")
        fflush(stdout)

        vm.start { result in
            switch result {
            case .success:
                guard let macAddress = self.macAddress else {
                    print("VM started successfully! (No network configuration found)")
                    fflush(stdout)
                    return
                }
                
                print("VM boot initiated. MAC address: \(macAddress)")
                print("Waiting for guest OS to allocate IP and start SSH...")
                fflush(stdout)
                
                Task {
                    var guestIp: String? = nil
                    let startTime = Date()
                    
                    // Loop until IP is allocated, timeout after 2 minutes
                    while guestIp == nil {
                        if Date().timeIntervalSince(startTime) > 120 {
                            fputs("Error: Timeout waiting for guest IP allocation.\n", stderr)
                            exit(1)
                        }
                        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                        guestIp = getIPAddress(forMac: macAddress)
                    }
                    
                    let ip = guestIp!
                    print("Guest IP allocated: \(ip). Checking SSH readiness...")
                    fflush(stdout)
                    
                    // Loop until SSH port (22) is open, timeout after 2 minutes total
                    var sshReady = false
                    while !sshReady {
                        if Date().timeIntervalSince(startTime) > 120 {
                            fputs("Error: Timeout waiting for SSH port to open.\n", stderr)
                            exit(1)
                        }
                        sshReady = await checkSSHPort(ip: ip)
                        if !sshReady {
                            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                        }
                    }
                    
                    print("VM started successfully! IP: \(ip)")
                    fflush(stdout)
                }
                
            case .failure(let error):
                fputs("Error: VM startup failed: \(error.localizedDescription)\n", stderr)
                exit(1)
            }
        }
    }

    func windowWillClose(_ notification: Notification) {
        print("Window closing. Stopping VM...")
        fflush(stdout)
        vm.stop { _ in
            exit(0)
        }
    }
}
