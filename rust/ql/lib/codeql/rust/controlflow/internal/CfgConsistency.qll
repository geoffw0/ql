/**
 * Provides classes for recognizing control flow graph inconsistencies.
 */

private import rust
private import codeql.rust.controlflow.internal.ControlFlowGraphImpl::Consistency as Consistency
import Consistency
private import codeql.rust.controlflow.ControlFlowGraph
private import codeql.rust.controlflow.internal.ControlFlowGraphImpl as CfgImpl
private import codeql.rust.controlflow.internal.Completion

/**
 * All `Expr` nodes are `PostOrderTree`s
 */
query predicate nonPostOrderExpr(Expr e, string cls) {
  cls = e.getPrimaryQlClasses() and
  not e instanceof LetExpr and
  not e instanceof ParenExpr and
  exists(AstNode last, Completion c |
    CfgImpl::last(e, last, c) and
    last != e and
    c instanceof NormalCompletion
  )
}

/**
 * Holds if CFG scope `scope` lacks an initial AST node.  Overrides shared consistency predicate.
 */
query predicate scopeNoFirst(CfgScope scope) {
  Consistency::scopeNoFirst(scope) and
  not scope = any(Function f | not exists(f.getBody())) and
  not scope = any(ClosureExpr c | not exists(c.getBody()))
}

/** Holds if  `be` is the `else` branch of a `let` statement that results in a panic. */
private predicate letElsePanic(BlockExpr be) {
  be = any(LetStmt let).getLetElse().getBlockExpr() and
  exists(Completion c | CfgImpl::last(be, _, c) | completionIsNormal(c))
}

/**
 * Holds if `node` is lacking a successor. Overrides shared consistency predicate.
 */
query predicate deadEnd(CfgImpl::Node node) {
  Consistency::deadEnd(node) and
  not letElsePanic(node.getAstNode())
}
