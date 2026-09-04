import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

class ParsedWorkflow {
  const ParsedWorkflow({
    required this.workflowFileName,
    required this.workflowName,
    required this.triggerType,
    required this.triggerBranch,
  });

  final String workflowFileName;
  final String workflowName;
  final String triggerType; // 'push' or 'pullRequest'
  final String triggerBranch;

  bool matches({
    required String eventType, // 'push' or 'pull_request'
    required String branch,
  }) {
    final expectedEventType = switch (triggerType) {
      'push' => 'push',
      'pullRequest' => 'pull_request',
      _ => triggerType,
    };

    if (eventType != expectedEventType) {
      return false;
    }

    return _matchesBranch(triggerBranch, branch);
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

ParsedWorkflow? parseGenuineCiWorkflow(String source, String fileName) {
  try {
    final parseResult = parseString(content: source, throwIfDiagnostics: false);
    final visitor = _GenuineCiInitVisitor(fileName);
    parseResult.unit.accept(visitor);
    return visitor.workflow;
  } catch (_) {
    return null;
  }
}

class _GenuineCiInitVisitor extends RecursiveAstVisitor<void> {
  _GenuineCiInitVisitor(this.fileName);

  final String fileName;
  ParsedWorkflow? workflow;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    super.visitMethodInvocation(node);

    // Look for GenuineCI.init(...)
    final target = node.target;
    final methodName = node.methodName.name;

    if (target is SimpleIdentifier &&
        (target.name == 'GenuineCI' || target.name == 'GenuineCi') &&
        methodName == 'init') {
      _extractFromInitArgs(node.argumentList);
    }
  }

  void _extractFromInitArgs(ArgumentList argumentList) {
    String? workflowName;
    String? triggerType;
    String? triggerBranch;

    for (final argument in argumentList.arguments) {
      if (argument is NamedExpression) {
        final paramName = argument.name.label.name;
        final expression = argument.expression;

        if (paramName == 'workflowName') {
          workflowName = _extractStringValue(expression);
        } else if (paramName == 'ciTrigger') {
          if (expression is MethodInvocation) {
            final methodName = expression.methodName.name;
            if (methodName == 'push' || methodName == 'pullRequest') {
              triggerType = methodName;
              for (final triggerArg in expression.argumentList.arguments) {
                if (triggerArg is NamedExpression &&
                    triggerArg.name.label.name == 'branch') {
                  triggerBranch = _extractStringValue(triggerArg.expression);
                }
              }
            }
          }
        }
      }
    }

    if (workflowName != null && triggerType != null && triggerBranch != null) {
      workflow = ParsedWorkflow(
        workflowFileName: fileName,
        workflowName: workflowName,
        triggerType: triggerType,
        triggerBranch: triggerBranch,
      );
    }
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
