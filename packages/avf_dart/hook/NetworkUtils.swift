import Foundation


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

