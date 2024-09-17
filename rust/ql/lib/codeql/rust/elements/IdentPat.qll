// generated by codegen, do not edit
/**
 * This module provides the public class `IdentPat`.
 */

private import internal.IdentPatImpl
import codeql.rust.elements.Pat

/**
 * A binding pattern. For example:
 * ```
 * match x {
 *     Option::Some(y) => y,
 *     Option::None => 0,
 * };
 * ```
 * ```
 * match x {
 *     y@Option::Some(_) => y,
 *     Option::None => 0,
 * };
 * ```
 */
final class IdentPat = Impl::IdentPat;
