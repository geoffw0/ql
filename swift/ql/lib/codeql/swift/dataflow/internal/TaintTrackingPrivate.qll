private import swift
private import DataFlowPrivate
private import TaintTrackingPublic
private import codeql.swift.dataflow.DataFlow
private import codeql.swift.dataflow.Ssa
private import codeql.swift.controlflow.CfgNodes

/**
 * Holds if `node` should be a sanitizer in all global taint flow configurations
 * but not in local taint.
 */
predicate defaultTaintSanitizer(DataFlow::Node node) { none() }

cached
private module Cached {
  /**
   * Holds if the additional step from `nodeFrom` to `nodeTo` should be included
   * in all global taint flow configurations.
   */
  cached
  predicate defaultAdditionalTaintStep(DataFlow::Node nodeFrom, DataFlow::Node nodeTo) {
    // Flow through one argument of `appendLiteral` and `appendInterpolation` and to the second argument.
    exists(ApplyExpr apply1, ApplyExpr apply2, ExprCfgNode e |
      nodeFrom.asExpr() = [apply1, apply2].getAnArgument().getExpr() and
      apply1.getFunction() = apply2 and
      apply2.getStaticTarget().getName() = ["appendLiteral(_:)", "appendInterpolation(_:)"] and
      e.getExpr() = apply2.getAnArgument().getExpr() and
      nodeTo.asDefinition().(Ssa::WriteDefinition).isInoutDef(e)
    )
    or
    // Flow from the computation of the interpolated string literal to the result of the interpolation.
    exists(InterpolatedStringLiteralExpr interpolated |
      nodeTo.asExpr() = interpolated and
      nodeFrom.asExpr() = interpolated.getAppendingExpr()
    )
  }

  /**
   * Holds if taint propagates from `nodeFrom` to `nodeTo` in exactly one local
   * (intra-procedural) step.
   */
  cached
  predicate localTaintStepCached(DataFlow::Node nodeFrom, DataFlow::Node nodeTo) {
    defaultAdditionalTaintStep(nodeFrom, nodeTo)
  }
}

import Cached
