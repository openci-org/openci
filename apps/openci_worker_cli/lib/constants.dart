import 'package:openci_worker_cli/src/version.dart';

const version = packageVersion;

const baseVmName = 'tahoe-base_v1.2.3';
const sshUser = 'admin';
const sshPassword = 'admin';

const dockerImage = 'openci-ubuntu:latest';

const exitCodeUpdateRequested = 42;

const firebaseSignInUrl =
    'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword';
const firebaseTokenRefreshUrl = 'https://securetoken.googleapis.com/v1/token';

const maxJobTimeout = Duration(hours: 1);
