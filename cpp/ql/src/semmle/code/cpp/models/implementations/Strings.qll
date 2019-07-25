import semmle.code.cpp.models.interfaces.DataFlow
import semmle.code.cpp.models.interfaces.Taint

/**
 * The `std::basic_string` constructor(s).
 */
class StringConstructor extends DataFlowFunction {
  StringConstructor() {
    this.hasQualifiedName("std", "basic_string", "basic_string")
  }

  override predicate hasDataFlow(FunctionInput input, FunctionOutput output) {
    // flow from any constructor argument to return value
    input.isInParameter(_) and
    output.isOutReturnValue()
  }
}

/**
 * The standard function `std::string.c_str`.
 */
class StringCStr extends DataFlowFunction {
  StringCStr() {
    this.hasQualifiedName("std", "basic_string", "c_str")
  }

  override predicate hasDataFlow(FunctionInput input, FunctionOutput output) {
    // flow from string itself (qualifier) to return value
    input.isInQualifier() and
    output.isOutReturnValue()
  }
}

/**
 * The standard function `operator<<`, for example on `std::stringstream`.
 */
class InsertionOperator extends TaintFunction {
  InsertionOperator() {
    this.hasQualifiedName("std", "operator<<")
  }

  override predicate hasTaintFlow(FunctionInput input, FunctionOutput output) {
    (
      // flow from second argument to return value
      input.isInParameterPointer(1) and
      output.isOutReturnValue()
    ) or (
      // flow from return value to first argument
      // (this is a bit odd; another way to think of it is the sink effectively
      //  flowing from the first argument to the return value)
      input.isInReturnValue() and
      output.isOutParameterPointer(0)
    )
  }
}

/**
 * The standard function `std::stringstream.str`.
 */
class StringStreamStr extends TaintFunction {
  StringStreamStr() {
    this.hasQualifiedName("std", "basic_stringstream", "str")
  }

  override predicate hasTaintFlow(FunctionInput input, FunctionOutput output) {
    // flow from object itself (qualifier) to return value
    input.isInQualifier() and
    output.isOutReturnValue()
  }
}
