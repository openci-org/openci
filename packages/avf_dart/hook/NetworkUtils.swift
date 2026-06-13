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

// Helper to get the maximum lease time currently recorded for a MAC address
func getLatestLeaseTime(forMac mac: String) -> UInt32 {
    let leasePath = "/var/db/dhcpd_leases"
    guard let content = try? String(contentsOfFile: leasePath) else {
        return 0
    }
    
    let targetHwNormalized = normalizeMacAddress(mac)
    let blocks = content.components(separatedBy: "}")
    var maxLease: UInt32 = 0
    
    for block in blocks {
        let lines = block.components(separatedBy: "\n")
        var currentHw: String? = nil
        var currentLeaseStr: String? = nil
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("hw_address=") {
                currentHw = trimmed.replacingOccurrences(of: "hw_address=", with: "")
            } else if trimmed.hasPrefix("lease=") {
                currentLeaseStr = trimmed.replacingOccurrences(of: "lease=", with: "")
            }
        }
        
        if let hw = currentHw, let leaseStr = currentLeaseStr {
            let hwNormalized = normalizeMacAddress(hw)
            if hwNormalized == targetHwNormalized {
                let cleanLease = leaseStr.replacingOccurrences(of: "0x", with: "")
                if let leaseVal = UInt32(cleanLease, radix: 16) {
                    if leaseVal > maxLease {
                        maxLease = leaseVal
                    }
                }
            }
        }
    }
    return maxLease
}

// Helper to query DHCP leases file (/var/db/dhcpd_leases) for VM's IP address,
// but only returns the IP if the lease time is strictly greater than newerThanLeaseTime.
func getIPAddress(forMac mac: String, newerThanLeaseTime: UInt32 = 0) -> String? {
    let leasePath = "/var/db/dhcpd_leases"
    guard let content = try? String(contentsOfFile: leasePath) else {
        fputs("Debug Warning: Failed to read \(leasePath) from avf_helper\n", stderr)
        fflush(stderr)
        return nil
    }
    
    let targetHwNormalized = normalizeMacAddress(mac)
    let blocks = content.components(separatedBy: "}")
    for block in blocks.reversed() {
        let lines = block.components(separatedBy: "\n")
        var currentHw: String? = nil
        var currentIp: String? = nil
        var currentLeaseStr: String? = nil
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("hw_address=") {
                currentHw = trimmed.replacingOccurrences(of: "hw_address=", with: "")
            } else if trimmed.hasPrefix("ip_address=") {
                currentIp = trimmed.replacingOccurrences(of: "ip_address=", with: "")
            } else if trimmed.hasPrefix("lease=") {
                currentLeaseStr = trimmed.replacingOccurrences(of: "lease=", with: "")
            }
        }
        
        if let hw = currentHw, let ip = currentIp {
            let hwNormalized = normalizeMacAddress(hw)
            if hwNormalized == targetHwNormalized {
                if newerThanLeaseTime > 0 {
                    if let leaseStr = currentLeaseStr {
                        let cleanLease = leaseStr.replacingOccurrences(of: "0x", with: "")
                        if let leaseVal = UInt32(cleanLease, radix: 16) {
                            if leaseVal > newerThanLeaseTime {
                                return ip
                            }
                        }
                    }
                } else {
                    return ip
                }
            }
        }
    }
    return nil
}

