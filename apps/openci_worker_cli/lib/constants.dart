import 'package:openci_worker_cli/src/version.dart';

const version = packageVersion;

// macOS (Lume VM)
const baseVmName = 'tahoe-base_v1.1.1';
const sshUser = 'admin';
const sshPassword = 'admin';

// Linux (Docker)
const dockerImage = 'openci-ubuntu:latest';

// Exit codes for supervisor communication
const exitCodeUpdateRequested = 42;

const firebaseSignInUrl =
    'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword';
const firebaseTokenRefreshUrl = 'https://securetoken.googleapis.com/v1/token';
