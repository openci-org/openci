# Changelog

## 0.1.24

- Fix: Ensure all completion callback operations in `runInstall` are dispatched onto the main thread queue. This fixes the thread-safety assertion crash (exit code -5 / SIGTRAP) when instantiating `VZVirtualMachine` inside a background-thread callback context.

## 0.1.23

- Fix: macOS installation failed with exit code -5 (SIGTRAP) by wrapping installation sequence inside main thread queue and executing `dispatchMain()`.
- Fix: Automatic cleanup of existing `nvram.bin` inside target VM directory to prevent `File exists` error on installation retry.

## 0.1.22

- Maintenance: Bump version for synchronization and integration verification.

## 0.1.21

- Fix: Completely rewrite parallel download implementation to download chunk ranges to separate temporary chunk files (e.g. `.chunk0`, `.chunk1`), then merge them sequentially upon completion. This guarantees 100% sequential I/O per stream, fully resolving OS-level virtual disk bottlenecks and lock freezes while preserving high-speed multi-connection downloads.

## 0.1.20

- Feature: Restore parallel connection downloading to improve speed.
- Fix: Use `package:synchronized` Lock instead of self-implemented lock for thread-safe random disk writes.
- Fix: Add a progress watchdog timer (30s) that forcefully aborts HttpClient connections if overall download progress ceases.

## 0.1.19

- Fix: Rewrite `downloadFile` to use a single connection sequential download with robust appending. This avoids disk I/O bottlenecks and potential deadlock freezes on virtual disks during concurrent chunk writes.

## 0.1.18

- Fix: Enforce strict `206 Partial Content` check for range requests to prevent silent download freezes on CDN response anomalies.
- Fix: Add connection (15s) and response stream (30s) timeouts to HttpClient to avoid infinite hang-ups.
- Fix: Disable response auto-uncompression (`autoUncompress = false`) to bypass processing overhead on large binary downloads.
- Change: Reduce default download concurrency to 4.

## 0.1.17

- Fix: Create parent directory before opening file for write in `downloadFile` to prevent `PathNotFoundException` (No such file or directory) if the target download directory does not exist.

## 0.1.16

- Change: Boot macOS VMs with 8 GB of memory (was 4 GB). 4 GB was too small for Flutter/Xcode/iOS-simulator builds, causing in-guest memory pressure (and SSH drops / `act exited with code 255` when two workers shared a host). Memory is still clamped to the framework's allowed range.

## 0.1.15

- Fix: Probe SSH port 22 with a fresh `nc` subprocess on each attempt in `_waitForSshPort` instead of an in-process `Socket.connect`. A long-running worker process could cache a permanent `No route to host` (EHOSTUNREACH) state after a connect failed during the guest's early-boot network flap, then keep failing for the rest of the process lifetime even though the port was fully reachable (a fresh process / `nc` / `ssh` connected fine at the same time). Using a subprocess matches the ping probe and sidesteps the stale in-process socket/route state.

## 0.1.14

- Fix: Implement two-phase wait in `_waitForSshPort`. First wait for guest OS ping to succeed (resolves ARP and routes), and only then attempt `Socket.connect`. This prevents Dart VM socket from encountering and caching a permanent `No route to host` error state when the VM boots up.

## 0.1.13

- Fix: Re-create `InternetAddress` instance on every connection attempt inside `_waitForSshPort` to bypass potential Socket DNS/resolution caching bugs in Dart VM.

## 0.1.12

- Fix: Use explicit `InternetAddress` with `InternetAddressType.IPv4` in `_waitForSshPort` to bypass any IPv6 lookup fallback issues in Dart's `Socket.connect`.
- Fix: Use absolute path `/sbin/ping` for the force-ARP workaround and print detailed execution output to diagnose command execution in non-interactive background environments.

## 0.1.11

- Fix: Connect directly to IP string in `_waitForSshPort` to avoid potential IPv6 mapping or resolution bugs in Dart's `InternetAddress.lookup`.

## 0.1.10

- Fix: Prevent picking up stale DHCP lease records from `/var/db/dhcpd_leases` on boot. Prefetch the latest lease timestamp before VM startup and ignore any leases older than or equal to that timestamp.

## 0.1.9

- Fix: Remove unique MAC address generation during VM cloning. macOS guest OS configures its network interface (en0) based on the original fixed MAC address, and altering it causes DHCP lease allocation timeouts.

## 0.1.8

- Fix: Resolve Dart VM socket connection caching issues when checking SSH port availability by performing a dynamic IP address lookup before connecting and increasing retry interval to 5 seconds.

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
