"""Run one prebuilt Patrol XCTest on its assigned simulator."""
import json
import plistlib
import signal
import socket
import subprocess
import sys
import tempfile
from pathlib import Path
from urllib.parse import urlparse

APP_ID = "org.openci.virtualBleExample"


def simctl(*args):
    return subprocess.check_output(["xcrun", "simctl", *args], text=True, timeout=90).strip()


def available_ports():
    # Patrol uses one port for XCTest and the next one for the app.
    for _ in range(30):
        with socket.socket() as first, socket.socket() as second:
            first.bind(("127.0.0.1", 0))
            port = first.getsockname()[1]
            if port < 65535:
                try:
                    second.bind(("127.0.0.1", port + 1))
                    return port
                except OSError:
                    continue
    raise RuntimeError("Could not allocate a pair of Patrol ports")


def main(udid, endpoint, output):
    role = urlparse(endpoint).path.removeprefix("/")
    if role not in ("A", "B"):
        raise ValueError("Expected endpoint /A or /B")
    products = Path("build/ios_integ/Build/Products")
    original, = products.glob("Runner_*iphonesimulator*.xctestrun")
    spec = plistlib.loads(original.read_bytes())
    port = available_ports()
    spec["RunnerUITests"]["EnvironmentVariables"]["PATROL_TEST_PORT"] = str(port)
    for key, value in [("PATROL_TEST_SERVER_PORT", port), ("PATROL_APP_SERVER_PORT", port + 1)]:
        simctl("spawn", udid, "launchctl", "setenv", key, str(value))
    simctl("install", udid, products / "Debug-iphonesimulator/Runner.app")

    def app_tmp():
        return Path(simctl("get_app_container", udid, APP_ID, "data")) / "tmp"

    evidence = "openci-virtual-ble-result.json"
    directory = app_tmp()
    (directory / evidence).unlink(missing_ok=True)
    (directory / "openci-virtual-ble.json").write_text(json.dumps({"endpoint": endpoint}))
    log = output / f"{role}.log"
    print(f"Running Patrol on {role} ({udid}), log: {log}", flush=True)
    with tempfile.NamedTemporaryFile(dir=products, suffix=".xctestrun") as temp, log.open("w") as stream:
        plistlib.dump(spec, temp)
        temp.flush()
        try:
            subprocess.run([
                "xcodebuild", "test-without-building", "-xctestrun", temp.name,
                "-destination", f"platform=iOS Simulator,id={udid}",
                "-only-testing:RunnerUITests", "-parallel-testing-enabled", "NO",
                "-resultBundlePath", output / f"{role}.xcresult",
            ], stdout=stream, stderr=subprocess.STDOUT, timeout=600, check=True)
            # XCTest can return zero if discovery found no tests. Require UI evidence.
            result = json.loads((app_tmp() / evidence).read_text())
            if result["role"] != role:
                raise ValueError(f"Unexpected evidence: {result}")
            (output / f"{role}.json").write_text(json.dumps(result))
        except Exception:
            print(log.read_text()[-16000:], flush=True)
            raise


if __name__ == "__main__":
    # Let subprocess.run tear down xcodebuild when the other peer fails.
    def stop(signum, frame):
        raise SystemExit(128 + signum)
    signal.signal(signal.SIGTERM, stop)
    main(sys.argv[1], sys.argv[2], Path(sys.argv[3]))
