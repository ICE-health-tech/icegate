import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'dart:io';

class V extends RecursiveAstVisitor<void> {
  String? cls;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final prev = cls;
    cls = node.name.lexeme;
    super.visitClassDeclaration(node);
    cls = prev;
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final ret = node.returnType?.toSource() ?? '';
    if (ret.endsWith('Column')) {
      final body = node.body;
      if (body is! ExpressionFunctionBody) {
        print('${cls}.${node.name.lexeme}: BODY NOT EXPR (${body.runtimeType})');
        return;
      }
      var e = body.expression;
      final buf = StringBuffer('${cls}.${node.name.lexeme}: ');
      if (e is FunctionExpressionInvocation) {
        var target = e.function;
        var depth = 0;
        Expression? last;
        while (target is MethodInvocation) {
          buf.write('${target.methodName.name} -> ');
          final t = target.target;
          last = t;
          if (t == null) break;
          target = t;
          depth++;
          if (depth > 20) break;
        }
        buf.write('[end target: ${last.runtimeType}]');
      } else {
        buf.write('!! NOT FunctionExpressionInvocation: ${e.runtimeType} :: ${e.toSource()}');
      }
      print(buf.toString());
    }
    super.visitMethodDeclaration(node);
  }
}

void main(List<String> args) {
  final src = File(args[0]).readAsStringSync();
  final result = parseString(content: src, throwIfDiagnostics: false);
  for (final d in result.errors) {
    print('PARSE ERROR: ${d.message} @ ${d.offset}');
  }
  result.unit.accept(V());
}