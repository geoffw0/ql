import semmle.code.cpp.Function
import semmle.code.cpp.models.interfaces.Alias
import semmle.code.cpp.models.interfaces.DataFlow
import semmle.code.cpp.models.interfaces.SideEffect

/**
 * The standard function templates `std::move` and `std::identity`
 */
class IdentityFunction extends DataFlowFunction, SideEffectFunction, AliasFunction {
  IdentityFunction() {
    this.getNamespace().getParentNamespace() instanceof GlobalNamespace and
    this.getNamespace().getName() = "std" and
    ( 
      this.getName() = "move" or
      this.getName() = "forward"
    )
  }

  override predicate neverReadsMemory() {
    any()
  }

  override predicate neverWritesMemory() {
    any()
  }

  override predicate parameterNeverEscapes(int index) {
    none()
  }

  override predicate parameterEscapesOnlyViaReturn(int index) {
    // These functions simply return the argument value.
    index = 0
  }

  override predicate parameterIsAlwaysReturned(int index) {
    // These functions simply return the argument value.
    index = 0
  }

  override predicate hasDataFlow(FunctionInput input, FunctionOutput output) {
    // These functions simply return the argument value.
    input.isInParameter(0) and output.isOutReturnValue()
  }
}
