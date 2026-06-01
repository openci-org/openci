import Foundation

// main.swift は Swiftc において暗黙的にエントリーポイント（トップレベルコード）となります。
// -parse-as-library フラグなしでコンパイルするため、@main 宣言は不要です。

let args = CommandLine.arguments
guard args.count >= 2 else {
    printUsage()
    exit(1)
}

let subcommand = args[1]

switch subcommand {
case "fetch-ipsw-url":
    await runFetchIpswUrl(args: args)

case "install":
    await runInstall(args: args)

case "boot":
    runBoot(args: args)

default:
    print("Error: Unknown subcommand: \(subcommand)", to: &errStream)
    exit(1)
}
