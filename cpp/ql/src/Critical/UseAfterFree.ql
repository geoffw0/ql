/**
 * @name Potential use after free
 * @description An allocated memory block is used after it has been freed. Behavior in such cases is undefined and can cause memory corruption.
 * @kind path-problem
 * @id cpp/use-after-free
 * @problem.severity warning
 * @security-severity 9.3
 * @tags reliability
 *       security
 *       external/cwe/cwe-416
 */

import cpp
import semmle.code.cpp.ir.dataflow.DataFlow
import DataFlow::PathGraph

/**
 * `e` is an expression that is being freed.
 */
predicate isFreeExpr(Expr e) {
  exists(FunctionCall fc |
    fc.getTarget().hasGlobalOrStdName("free") and
    e = fc.getArgument(0)
  )
  or
  any(DeleteExpr de).getExpr() = e
  or
  any(DeleteArrayExpr dae).getExpr() = e
}

/**
 * `e` is an expression that (may) dereference `v`.
 */
predicate isDerefExpr(Expr e, StackVariable v) {
  v.getAnAccess() = e and dereferenced(e)
  or
  isDerefByCallExpr(_, _, e, v)
}

/**
 * `va` is passed by value as (part of) the `i`th argument in
 * call `c`. The target function is either a library function
 * or a source code function that dereferences the relevant
 * parameter.
 */
predicate isDerefByCallExpr(Call c, int i, VariableAccess va, StackVariable v) {
  v.getAnAccess() = va and
  va = c.getAnArgumentSubExpr(i) and
  not c.passesByReference(i, va) and
  (c.getTarget().hasEntryPoint() implies isDerefExpr(_, c.getTarget().getParameter(i)))
}

/**
 * Dataflow configuration tracking pointers that are freed to their use.
 */
class UseAfterFreeConfig extends DataFlow::Configuration {
  UseAfterFreeConfig() { this = "UseAfterFree" }

  override predicate isSource(DataFlow::Node node) {
    isFreeExpr(node.asDefiningArgument())
  }

  override predicate isSink(DataFlow::Node node) {
    isDerefExpr(node.asExpr(), _)
  }

  override predicate isBarrierOut(DataFlow::Node node) {
    isSink(node) // only report first use
    //node.asExpr() instanceof VariableAccess
    or
    dereferenced(node.asExpr())
  }
}

from UseAfterFreeConfig c, DataFlow::PathNode source, DataFlow::PathNode sink
where c.hasFlowPath(source, sink)
select sink, source, sink, "Memory may have been previously freed $@", source, "here"
