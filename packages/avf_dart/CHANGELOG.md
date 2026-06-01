# Changelog

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
