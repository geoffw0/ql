// generated by codegen, do not edit
/**
 * This module provides the generated definition of `AsmExpr`.
 * INTERNAL: Do not import directly.
 */

private import codeql.rust.internal.generated.Synth
private import codeql.rust.internal.generated.Raw
import codeql.rust.elements.Expr
import codeql.rust.elements.internal.ExprImpl::Impl as ExprImpl

/**
 * INTERNAL: This module contains the fully generated definition of `AsmExpr` and should not
 * be referenced directly.
 */
module Generated {
  /**
   * An inline assembly expression. For example:
   * ```
   * unsafe {
   *     builtin # asm(_);
   * }
   * ```
   * INTERNAL: Do not reference the `Generated::AsmExpr` class directly.
   * Use the subclass `AsmExpr`, where the following predicates are available.
   */
  class AsmExpr extends Synth::TAsmExpr, ExprImpl::Expr {
    override string getAPrimaryQlClass() { result = "AsmExpr" }

    /**
     * Gets the expression of this asm expression.
     */
    Expr getExpr() {
      result = Synth::convertExprFromRaw(Synth::convertAsmExprToRaw(this).(Raw::AsmExpr).getExpr())
    }
  }
}
