import Foundation

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
    runInstall(args: args)

case "boot":
    runBoot(args: args)

default:
    print("Error: Unknown subcommand: \(subcommand)", to: &errStream)
    exit(1)
}
