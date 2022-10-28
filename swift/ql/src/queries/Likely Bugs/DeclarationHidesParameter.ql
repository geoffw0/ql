/**
 * @name Declaration hides parameter
 * @description TODO
 * @kind problem
 * @problem.severity recommendation
 * @precision high
 * @id swift/declaration-hides-parameter
 * @tags maintainability
 *       reliability
 */

import swift

// TODO: possibly speed up via a structure similar to the CPP version:
//predicate functionParameterNames(AbstractFunctionDecl f, ParamDecl p)
//predicate localVariableNames(AbstractFunctionDecl f, VarDecl v)

from AbstractFunctionDecl f, ParamDecl p, VarDecl v
where
  pragma[only_bind_out](f).getAParam() = p and
  v.getEnclosingFunction() = pragma[only_bind_out](f) and
  p.getName() = v.getName() and
  not v instanceof ParamDecl
  // TODO: and does not have an initializer containing an access to p / same name as p.
  //v.hasParentPattern()
  //v.hasParentInitializer()
select v, "here" // TODO: message
