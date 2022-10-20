/**
 * Provides classes and predicates for identifying values that are compile
 * time constant ("constant propagation").
 */

import swift
import codeql.swift.dataflow.DataFlow

/**
 * Holds if `src` is a literal and `dest` is an expression that must be
 * constant and derived from `src` (not necessarily equal).
 */
predicate constantPropagation(DataFlow::Node src, DataFlow::Node dest) {
  // literal
  src.asExpr() instanceof LiteralExpr and
  src = dest
  or
  // local data flow
  exists(DataFlow::Node pred |
    DataFlow::localFlowStep(pred, dest) and constantPropagation(src, pred)
  )
  or
  // flow through unary operators where input is constant
  exists(DataFlow::Node pred | pred.asExpr() = dest.asExpr().(PrefixUnaryExpr).getOperand() |
    constantPropagation(src, pred)
  )
  or
  // flow through binary operators where all inputs are constant
  exists(DataFlow::Node pred | pred.asExpr() = dest.asExpr().(BinaryExpr).getAnOperand() |
    constantPropagation(src, pred)
  ) and
  forall(DataFlow::Node pred | pred.asExpr() = dest.asExpr().(BinaryExpr).getAnOperand() |
    constantPropagation(_, pred)
  )
  or
  // flow through ternary operators when the condition is a constant
  exists(IfExpr ie, DataFlow::Node condSrc, DataFlow::Node cond, DataFlow::Node pred |
    ie = dest.asExpr().(IfExpr) and
    cond.asExpr() = ie.getCondition() and
    constantPropagation(condSrc, cond) and
    pred.asExpr() = ie.getBranch(condSrc.asExpr().(BooleanLiteralExpr).getValue()) and
    constantPropagation(src, pred)
  )
  or
  // flow through ternary operators when the values are equal
  exists(IfExpr ie, DataFlow::Node thenNode, DataFlow::Node elseNode, DataFlow::Node altSrc |
    ie = dest.asExpr().(IfExpr) and
    thenNode.asExpr() = ie.getThenExpr() and
    elseNode.asExpr() = ie.getElseExpr() and
    constantPropagation(src, thenNode) and
    constantPropagation(altSrc, elseNode) and
    ???
  )
}

/**
 * A compile-time constant expression.
 */
class CompileTimeConstantExpr extends Expr {
  CompileTimeConstantExpr() {
    exists(DataFlow::Node dest |
      constantPropagation(_, dest) and
      dest.asExpr() = this
    )
  }
}
