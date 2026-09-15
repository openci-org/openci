"""Exercise terminal input and VM shutdown against a local API and test files."""

import base64
import fcntl
import http.server
import json
import os
from pathlib import Path
import pty
import select
import signal
import struct
import subprocess
import sys
import tempfile
import termios
import threading
import time


def run_case(directory, credentials, keys=None, stop_signal=None):
    master, slave = pty.openpty()
    # Include pixel dimensions: a zero-filled PTY does not represent the
    # terminal size that exposed the macOS ARM64 ioctl memory corruption.
    fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack('HHHH', 59, 45, 324, 816))
    original = termios.tcgetattr(slave)
    process = subprocess.Popen(
        [*sys.argv[1:], str(credentials)],
        cwd=directory,
        env=dict(os.environ, TERM='xterm-256color'),
        stdin=slave, stdout=slave, stderr=slave,
    )
    output = bytearray()
    try:
        deadline = time.monotonic() + 15
        while b'Select a secret file' not in output:
            if time.monotonic() > deadline or process.poll() is not None:
                raise AssertionError('Picker did not open: ' + output.decode(errors='replace'))
            if select.select([master], [], [], 0.1)[0]:
                output.extend(os.read(master, 65536))
        # The first frame is rendered immediately before raw input is enabled.
        while termios.tcgetattr(slave)[3] & (termios.ECHO | termios.ICANON):
            if time.monotonic() > deadline or process.poll() is not None:
                raise AssertionError('Picker did not enable raw input')
            time.sleep(0.01)
        if stop_signal is not None:
            process.send_signal(stop_signal)
        else:
            os.write(master, keys)
        deadline = time.monotonic() + 15
        while process.poll() is None:
            if time.monotonic() > deadline:
                raise AssertionError('Picker did not exit: ' + output.decode(errors='replace'))
            if select.select([master], [], [], 0.1)[0]:
                output.extend(os.read(master, 65536))
        while select.select([master], [], [], 0.05)[0]:
            output.extend(os.read(master, 65536))
        assert termios.tcgetattr(slave) == original, 'Terminal settings were not restored'
        return process.returncode, bytes(output)
    finally:
        if process.poll() is None:
            process.kill()
            process.wait()
        os.close(master)
        os.close(slave)


def main():
    requests = []

    class Handler(http.server.BaseHTTPRequestHandler):
        def do_POST(self):
            body = self.rfile.read(int(self.headers['Content-Length']))
            requests.append((self.path, self.headers.get('Authorization'), json.loads(body)))
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(b'{"success":true}')

        def log_message(self, *_):
            pass

    server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), Handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        with tempfile.TemporaryDirectory(prefix='genuineci-secret-file-pty-') as temporary:
            directory = Path(temporary)
            nested = directory / 'secrets'
            nested.mkdir()
            payload = b'  {"project_id":"terminal-test-only"}\n'
            (nested / 'google-services.json').write_bytes(payload)
            unicode_name = 'signing 日本語🔑.p12'
            binary = bytes([0, 255, 128, 13, 10, 0])
            (directory / unicode_name).write_bytes(binary)
            credentials = directory / 'credentials.json'
            credentials.write_text(json.dumps({
                'active_profile': 'test',
                'profiles': {'test': {
                    'server_url': f'http://127.0.0.1:{server.server_port}',
                    'team_id': 'test-team', 'token': 'fake-test-token',
                }},
            }))
            before_credentials = credentials.read_bytes()

            status, output = run_case(directory, credentials, b'sec\t\rgoogle\t\r')
            assert status == 0, output.decode(errors='replace')
            assert requests == [(
                '/teams/test-team/secrets', 'Bearer fake-test-token',
                {'name': 'GOOGLE_SERVICES_JSON_BASE64', 'value': base64.b64encode(payload).decode()},
            )]
            assert payload not in output and base64.b64encode(payload) not in output
            print('PASS: Tab completion, Base64 upload, normal exit, terminal restoration')

            status, output = run_case(directory, credentials, unicode_name.encode() + b'\r')
            assert status == 0, output.decode(errors='replace')
            assert len(requests) == 2
            assert base64.b64decode(requests[-1][2]['value']) == binary
            assert binary not in output and base64.b64encode(binary) not in output
            print('PASS: Unicode path input and binary file upload')

            for label, keys, stop_signal in [
                ('Esc', b'\x1b', None),
                ('Ctrl+C', b'\x03', None),
                ('SIGINT', None, signal.SIGINT),
                ('SIGTERM', None, signal.SIGTERM),
            ]:
                before = len(requests)
                status, output = run_case(directory, credentials, keys, stop_signal)
                assert status == 1, (label, status, output.decode(errors='replace'))
                assert len(requests) == before
                print(f'PASS: {label} cancels without uploading and restores the terminal')
            assert credentials.read_bytes() == before_credentials
    finally:
        server.shutdown()
        server.server_close()
        thread.join()


if __name__ == '__main__':
    main()
