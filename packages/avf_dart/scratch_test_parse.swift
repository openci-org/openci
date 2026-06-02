import Foundation

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

func getIPAddress(forMac mac: String) -> String? {
    let leasePath = "/var/db/dhcpd_leases"
    guard let content = try? String(contentsOfFile: leasePath, encoding: .utf8) else {
        return nil
    }
    let targetHwNormalized = normalizeMacAddress(mac)
    let blocks = content.components(separatedBy: "}")
    for block in blocks {
        let lines = block.components(separatedBy: "\n")
        var currentHw: String? = nil
        var currentIp: String? = nil
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
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

let args = CommandLine.arguments
if args.count > 1 {
    let targetMac = args[1]
    print("Resolved IP for \(targetMac): \(getIPAddress(forMac: targetMac) ?? "nil")")
} else {
    print("Usage: swift scratch_test_parse.swift <mac-address>")
}
