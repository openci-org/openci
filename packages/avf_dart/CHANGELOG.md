# Changelog

## 0.1.7

- Feature: Automatically generate a unique random MAC address during VM cloning in virtual_machine_manager.dart. This prevents MAC address and IP address conflicts when launching multiple VMs concurrently on the same host.

## 0.1.6

- Fix: Re-add virtual graphics, keyboard, and pointing devices to VM configuration in runBoot. While the host process runs in headless mode, macOS guest OS requires these basic virtual hardware interfaces to boot successfully and open the SSH port.

## 0.1.5

- Fix: Run macOS VM in headless mode by removing GUI dependencies (NSApplication, VZVirtualMachineView, AppDelegate) and keeping the process alive via dispatchMain() to prevent VM boot hang ups on headless host runners.

## 0.1.4

- Fix: Move SSH port checking logic from Swift (NWConnection) to Dart (Socket.connect) to resolve network path resolution delays and hang ups in virtual networks.

## 0.1.3

- Fix: Prioritize latest version in pub-cache and skip resolving dummy install/bin paths to ensure the correct avf_helper version is chosen in AOT-compiled environments.

## 0.1.2

- Fix: Bump SSH and guest IP allocation timeout limits from 120 seconds to 300 seconds (5 minutes) to prevent VM startup timeouts on heavily-loaded macOS hosts.

## 0.1.1

- Fix: Support dynamic .pub-cache fallback resolving for avf_helper binary when running as an AOT-compiled global package.

## 0.1.0

- Initial release.
