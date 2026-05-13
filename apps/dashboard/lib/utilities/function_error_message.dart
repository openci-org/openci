import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/app_strings.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class FunctionErrorMessage {
  const FunctionErrorMessage({
    required this.message,
    required this.shouldReport,
    this.code,
  });

  final String message;
  final bool shouldReport;
  final String? code;

  factory FunctionErrorMessage.from(FirebaseFunctionsException error) {
    return FunctionErrorMessage._fromFunctionsException(error);
  }

  static Future<FunctionErrorMessage> capture(
    FirebaseFunctionsException error, {
    StackTrace? stackTrace,
  }) async {
    final errorMessage = FunctionErrorMessage.from(error);
    _debugPrint(error, stackTrace);
    if (!errorMessage.shouldReport) {
      return errorMessage;
    }

    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) async {
        await scope.setTag('error.source', 'firebase_functions');
        final code = errorMessage.code;
        if (code != null) {
          await scope.setTag('firebase.functions.code', code);
        }
      },
    );

    return errorMessage;
  }

  static void _debugPrint(
    FirebaseFunctionsException error,
    StackTrace? stackTrace,
  ) {
    if (!kDebugMode) return;

    debugPrint(
      'FirebaseFunctionsException: '
      'code=${error.code}, '
      'message=${error.message}, '
      'details=${error.details}',
    );
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }

  factory FunctionErrorMessage._fromFunctionsException(
    FirebaseFunctionsException error,
  ) {
    final functionErrors = t.common.functionErrors;
    switch (error.code) {
      case 'cancelled':
        return FunctionErrorMessage(
          message: _messageOr(error, functionErrors.cancelled),
          shouldReport: false,
          code: error.code,
        );
      case 'invalid-argument':
      case 'out-of-range':
        return FunctionErrorMessage(
          message: _messageOr(error, functionErrors.invalidArgument),
          shouldReport: false,
          code: error.code,
        );
      case 'failed-precondition':
        return FunctionErrorMessage(
          message: _messageOr(error, functionErrors.failedPrecondition),
          shouldReport: false,
          code: error.code,
        );
      case 'not-found':
        return FunctionErrorMessage(
          message: _messageOr(error, functionErrors.notFound),
          shouldReport: false,
          code: error.code,
        );
      case 'already-exists':
        return FunctionErrorMessage(
          message: _messageOr(error, functionErrors.alreadyExists),
          shouldReport: false,
          code: error.code,
        );
      case 'unauthenticated':
        return FunctionErrorMessage(
          message: functionErrors.unauthenticated,
          shouldReport: false,
          code: error.code,
        );
      case 'permission-denied':
        return FunctionErrorMessage(
          message: functionErrors.permissionDenied,
          shouldReport: false,
          code: error.code,
        );
      case 'resource-exhausted':
        return FunctionErrorMessage(
          message: functionErrors.resourceExhausted,
          shouldReport: false,
          code: error.code,
        );
      case 'aborted':
        return FunctionErrorMessage(
          message: functionErrors.aborted,
          shouldReport: false,
          code: error.code,
        );
      case 'unavailable':
      case 'deadline-exceeded':
        return FunctionErrorMessage(
          message: functionErrors.unavailable,
          shouldReport: true,
          code: error.code,
        );
      case 'internal':
        return FunctionErrorMessage(
          message: functionErrors.internal,
          shouldReport: true,
          code: error.code,
        );
      case 'unknown':
        return FunctionErrorMessage(
          message: functionErrors.unknown,
          shouldReport: true,
          code: error.code,
        );
      case 'data-loss':
      default:
        return FunctionErrorMessage(
          message: functionErrors.unexpected,
          shouldReport: true,
          code: error.code,
        );
    }
  }

  static String _messageOr(
    FirebaseFunctionsException error,
    String fallback,
  ) {
    final message = error.message?.trim();
    if (message == null || message.isEmpty) {
      return fallback;
    }
    return message;
  }
}
