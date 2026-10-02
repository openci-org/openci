import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

/// An invalid workflow trigger configuration.
class WorkflowConfigurationException extends FormatException {
  const WorkflowConfigurationException(super.message);
}

class ParsedWorkflow {
  const ParsedWorkflow({
    required this.workflowFileName,
    required this.workflowName,
    required this.ciTriggers,
  });

  final String workflowFileName;
  final String workflowName;
  final List<ParsedCITrigger> ciTriggers;

  bool matches({required String eventType, required String branch}) =>
      ciTriggers.any(
        (trigger) => trigger.matches(eventType: eventType, branch: branch),
      );
}

class ParsedCITrigger {
  const ParsedCITrigger({
    required this.type,
    required this.branch,
    this.whenChanged,
  });

  final String type; // 'push' or 'pullRequest'
  final String branch;
  final List<String>? whenChanged;

  bool matches({
    required String eventType, // 'push' or 'pull_request'
    required String branch,
  }) {
    final expectedEventType = switch (type) {
      'push' => 'push',
      'pullRequest' => 'pull_request',
      _ => null,
    };

    if (eventType != expectedEventType) {
      return false;
    }

    return _matchesBranch(this.branch, branch);
  }

  static bool _matchesBranch(String pattern, String branch) {
    if (pattern == '*' || pattern == branch) {
      return true;
    }

    if (pattern.contains('*')) {
      final regexPattern =
          '^${RegExp.escape(pattern).replaceAll(r'\*', '.*')}\$';
      return RegExp(regexPattern).hasMatch(branch);
    }

    return false;
  }
}

ParsedWorkflow? parseOpenCIWorkflow(String source, String fileName) {
  try {
    final parseResult = parseString(content: source, throwIfDiagnostics: false);
    final visitor = _OpenCIInitVisitor(fileName);
    parseResult.unit.accept(visitor);
    return visitor.workflow;
  } on WorkflowConfigurationException {
    rethrow;
  } catch (_) {
    return null;
  }
}

class _OpenCIInitVisitor extends RecursiveAstVisitor<void> {
  _OpenCIInitVisitor(this.fileName);

  final String fileName;
  ParsedWorkflow? workflow;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    super.visitMethodInvocation(node);

    // Look for OpenCI.init(...)
    final target = node.target;
    final methodName = node.methodName.name;

    if (target is SimpleIdentifier &&
        target.name == 'OpenCI' &&
        methodName == 'init') {
      _extractFromInitArgs(node.argumentList);
    }
  }

  void _extractFromInitArgs(ArgumentList argumentList) {
    String? workflowName;
    List<ParsedCITrigger>? ciTriggers;

    for (final argument in argumentList.arguments) {
      if (argument is NamedExpression) {
        final paramName = argument.name.label.name;
        final expression = argument.expression;

        if (paramName == 'workflowName') {
          workflowName = _extractStringValue(expression);
        } else if (paramName == 'ciTriggers') {
          ciTriggers = _extractTriggers(expression);
        }
      }
    }

    if (workflowName != null && ciTriggers != null) {
      workflow = ParsedWorkflow(
        workflowFileName: fileName,
        workflowName: workflowName,
        ciTriggers: ciTriggers,
      );
    }
  }

  List<ParsedCITrigger>? _extractTriggers(Expression expression) {
    if (expression is! ListLiteral) return null;

    final triggers = <ParsedCITrigger>[];
    for (final element in expression.elements) {
      if (element is! Expression) return null;
      final trigger = _extractTrigger(element);
      if (trigger == null) return null;
      triggers.add(trigger);
    }
    return triggers;
  }

  ParsedCITrigger? _extractTrigger(Expression expression) {
    String? className;
    String? triggerType;
    ArgumentList? argumentList;

    if (expression is MethodInvocation) {
      final target = expression.target;
      if (target is SimpleIdentifier) {
        className = target.name;
      } else if (target is PrefixedIdentifier) {
        className = target.identifier.name;
      }
      triggerType = expression.methodName.name;
      argumentList = expression.argumentList;
    } else if (expression is InstanceCreationExpression) {
      final constructor = expression.constructorName;
      if (constructor.name != null) {
        className = constructor.type.name.lexeme;
        triggerType = constructor.name!.name;
      } else {
        // Before resolution, `const CITrigger.push(...)` is a prefixed type.
        className = constructor.type.importPrefix?.name.lexeme;
        triggerType = constructor.type.name.lexeme;
      }
      argumentList = expression.argumentList;
    }

    if (className != 'CITrigger' ||
        (triggerType != 'push' && triggerType != 'pullRequest') ||
        argumentList == null) {
      return null;
    }

    String? branch;
    List<String>? whenChanged;
    for (final argument in argumentList.arguments) {
      if (argument is! NamedExpression) continue;
      if (argument.name.label.name == 'branch') {
        branch = _extractStringValue(argument.expression);
      } else if (argument.name.label.name == 'whenChanged') {
        whenChanged = _extractWhenChanged(argument.expression, triggerType!);
      }
    }
    if (branch == null) return null;
    return ParsedCITrigger(
      type: triggerType!,
      branch: branch,
      whenChanged: whenChanged,
    );
  }

  List<String>? _extractWhenChanged(Expression expression, String triggerType) {
    Never invalid(String reason) => throw WorkflowConfigurationException(
      '$fileName: CITrigger.$triggerType.whenChanged $reason',
    );

    if (expression is NullLiteral) return null;
    if (expression is! ListLiteral || expression.elements.isEmpty) {
      invalid('must be a non-empty literal list of strings');
    }

    final patterns = <String>[];
    for (final element in expression.elements) {
      if (element is! Expression) {
        invalid('must contain only literal strings');
      }
      final pattern = _extractStringValue(element);
      if (pattern == null) {
        invalid('must contain only literal strings');
      }
      if (pattern.trim().isEmpty ||
          pattern.startsWith('!') ||
          p.posix.isAbsolute(pattern) ||
          // Drive and UNC roots are invalid; leading glob escapes are allowed.
          p.windows.rootPrefix(pattern).length > 1 ||
          p.posix.split(pattern).contains('..')) {
        invalid('contains an invalid repository-relative pattern: "$pattern"');
      }
      try {
        Glob(pattern, context: p.posix, caseSensitive: true);
      } on FormatException catch (error) {
        invalid('contains an invalid glob "$pattern": ${error.message}');
      }
      patterns.add(pattern);
    }
    return List.unmodifiable(patterns);
  }

  String? _extractStringValue(Expression expression) {
    if (expression is SimpleStringLiteral) {
      return expression.value;
    } else if (expression is StringInterpolation) {
      final buffer = StringBuffer();
      for (final element in expression.elements) {
        if (element is InterpolationString) {
          buffer.write(element.value);
        } else {
          return null; // dynamic interpolation not statically resolvable
        }
      }
      return buffer.toString();
    }
    return null;
  }
}
