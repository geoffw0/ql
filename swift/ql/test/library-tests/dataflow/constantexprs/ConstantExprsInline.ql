import swift
import codeql.swift.dataflow.ConstantExprs
import TestUtilities.InlineExpectationsTest

class ConstantExprsTest extends InlineExpectationsTest {
  ConstantExprsTest() { this = "ConstantExprsTest" }

  override string getARelevantTag() { result = "constant" }

  override predicate hasActualResult(Location location, string element, string tag, string value) {
    exists(CallExpr sinkCall, CompileTimeConstantExpr e |
      sinkCall.getStaticTarget().getName() = "sink(_:)" and
      sinkCall.getArgument(0).getExpr() = e and
      location = e.getLocation() and
      element = e.toString() and
      tag = "constant" and
      value = ""
    )
  }
}
