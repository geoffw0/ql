// generated by codegen, do not edit
/**
 * This module provides the public class `AwaitExpr`.
 */

private import internal.AwaitExprImpl
import codeql.rust.elements.Expr

/**
 * An `await` expression. For example:
 * ```
 * async {
 *     let x = foo().await;
 *     x
 * }
 * ```
 */
final class AwaitExpr = Impl::AwaitExpr;
