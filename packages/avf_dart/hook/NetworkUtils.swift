import Foundation
import Network

// Helper to normalize MAC address string by removing leading zeros in each octet
// e.g. "e2:8c:5c:f5:07:be" -> "e2:8c:5c:f5:7:be"
func normalizeMacAddress(_ mac: String) -> String {
    let clean = mac.replacingOccurrences(of: "1,", with: "")
    let parts = clean.split(separator: ":")
    let normalizedParts = parts.map { part -> String in
        let partStr = String(part)
        if partStr.hasPrefix("0") && partStr.count > 1 {
            return String(partStr.dropFirst())
        }
        return partStr
    }
    return normalizedParts.joined(separator: ":").lowercased()
}

// Helper to query DHCP leases file (/var/db/dhcpd_leases) for VM's IP address
func getIPAddress(forMac mac: String) -> String? {
    let leasePath = "/var/db/dhcpd_leases"
    guard let content = try? String(contentsOfFile: leasePath) else {
        fputs("Debug Error: Failed to read \(leasePath) from avf_helper\n", stderr)
        fflush(stderr)
        return nil
    }
    
    let targetHwNormalized = normalizeMacAddress(mac)
    let blocks = content.components(separatedBy: "}")
    for block in blocks {
        let lines = block.components(separatedBy: "\n")
        var currentHw: String? = nil
        var currentIp: String? = nil
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("hw_address=") {
                currentHw = trimmed.replacingOccurrences(of: "hw_address=", with: "")
            } else if trimmed.hasPrefix("ip_address=") {
                currentIp = trimmed.replacingOccurrences(of: "ip_address=", with: "")
            }
        }
        
        if let hw = currentHw, let ip = currentIp {
            let hwNormalized = normalizeMacAddress(hw)
            if hwNormalized == targetHwNormalized {
                return ip
            }
        }
    }
    return nil
}

// Thread-safe wrapper to ensure the continuation is resumed exactly once
class SafeResumer: @unchecked Sendable {
    private var isResumed = false
    private let lock = NSLock()
    
    func resume(connection: NWConnection, continuation: CheckedContinuation<Bool, Never>, value: Bool) {
        lock.lock()
        defer { lock.unlock() }
        if !isResumed {
            isResumed = true
            connection.cancel()
            continuation.resume(returning: value)
        }
    }
}

// Helper to check if SSH port (22) is open on the guest IP using non-blocking async wait
func checkSSHPort(ip: String) async -> Bool {
    let host = NWEndpoint.Host(ip)
    let port = NWEndpoint.Port(integerLiteral: 22)
    let connection = NWConnection(host: host, port: port, using: .tcp)
    let resumer = SafeResumer()
    
    return await withCheckedContinuation { continuation in
        connection.stateUpdateHandler = { state in
            if case .ready = state {
                resumer.resume(connection: connection, continuation: continuation, value: true)
            } else if case .failed = state {
                resumer.resume(connection: connection, continuation: continuation, value: false)
            }
        }
        
        connection.start(queue: .global())
        
        // Timeout after 1.5 seconds
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
            resumer.resume(connection: connection, continuation: continuation, value: false)
        }
    }
}
