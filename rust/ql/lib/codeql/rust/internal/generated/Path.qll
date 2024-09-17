// generated by codegen, do not edit
/**
 * This module provides the generated definition of `Path`.
 * INTERNAL: Do not import directly.
 */

private import codeql.rust.internal.generated.Synth
private import codeql.rust.internal.generated.Raw
import codeql.rust.elements.internal.AstNodeImpl::Impl as AstNodeImpl
import codeql.rust.elements.internal.UnimplementedImpl::Impl as UnimplementedImpl

/**
 * INTERNAL: This module contains the fully generated definition of `Path` and should not
 * be referenced directly.
 */
module Generated {
  /**
   * A path. For example:
   * ```
   * foo::bar;
   * ```
   * INTERNAL: Do not reference the `Generated::Path` class directly.
   * Use the subclass `Path`, where the following predicates are available.
   */
  class Path extends Synth::TPath, AstNodeImpl::AstNode, UnimplementedImpl::Unimplemented {
    override string getAPrimaryQlClass() { result = "Path" }
  }
}
