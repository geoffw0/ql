import codeql_ruby.AST
import codeql_ruby.ast.Variable

query predicate variableAccess(VariableAccess access, Variable variable, VariableScope scope) {
  variable = access.getVariable() and
  scope = variable.getDeclaringScope()
}

query predicate explicitWrite(VariableWriteAccess write, AstNode assignment) {
  write.isExplicitWrite(assignment)
}

query predicate implicitWrite(VariableWriteAccess write) { write.isImplicitWrite() }

query predicate readAccess(VariableReadAccess read) { any() }
