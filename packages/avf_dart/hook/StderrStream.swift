import Foundation

struct StderrStream: TextOutputStream {
    mutating func write(_ string: String) {
        fputs(string, stderr)
    }
}

var errStream = StderrStream()

func printUsage() {
    print("Usage: avf_helper <subcommand> [args]", to: &errStream)
    print("Subcommands:", to: &errStream)
    print("  boot <disk-img-path> <nvram-path> <hardware-model-b64> <machine-identifier-b64> <mac-address>", to: &errStream)
    print("  fetch-ipsw-url <output-file>", to: &errStream)
    print("  install <ipsw-path> <disk-img-path> <nvram-path> <config-json-path>", to: &errStream)
}
