import semmle.code.cpp.models.interfaces.ArrayFunction
import semmle.code.cpp.models.interfaces.DataFlow
import semmle.code.cpp.models.interfaces.Taint

/**
 * The standard function `strlen` and its wide and Microsoft variants.
 */
class StrlenFunction extends TaintFunction, ArrayFunction {
  StrlenFunction() {
    exists(string name | hasGlobalOrStdName(name) |
      name = "strlen" or
      name = "wcslen"
    )
    or
    exists(string name | hasGlobalName(name) |
      name = "_mbslen" or
      name = "_mbslen_l" or
      name = "_mbstrlen" or
      name = "_mbstrlen_l"
    )
  }

  /**
   * The string argument passed into this `strlen` call.
   */
  int getStringArgument() { result = 0 }

  override predicate hasTaintFlow(FunctionInput input, FunctionOutput output) {
    input.isParameterDeref(getStringArgument()) and
    output.isReturnValue()
  }

  override predicate hasArrayInput(int param) { param = getStringArgument() }

  override predicate hasArrayWithNullTerminator(int param) { param = getStringArgument() }
}
