import swift
import TestUtilities.InlineExpectationsTest
import FlowConfig
import codeql.swift.dataflow.TaintTracking
import codeql.swift.dataflow.DataFlow

module TestConfiguration implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node src) { src instanceof FlowSource }

  predicate isSink(DataFlow::Node sink) {
    any()
  }

  predicate allowImplicitRead(DataFlow::Node node, DataFlow::ContentSet c) {
    isSink(node) and
    exists(NominalTypeDecl d, Decl cx |
      d.getType().getABaseType*().getUnderlyingType().getName().matches(
        ["Binding%", "State%"]) and
      cx.asNominalTypeDecl() = d and
      c.getAReadContent().(DataFlow::Content::FieldContent).getField() = cx.getAMember()
    )
  }
}

module TestFlow = TaintTracking::Global<TestConfiguration>;

module TestConfiguration2 implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node src) { any() }

  predicate isSink(DataFlow::Node sink) {
    exists(CallExpr sinkCall |
      sinkCall.getStaticTarget().getName().matches("sink%") and
      sinkCall.getAnArgument().getExpr() = sink.asExpr()
    )
  }
}

module TestFlow2 = TaintTracking::Global<TestConfiguration2>;

string describe(DataFlow::Node n) {
  (TestConfiguration::isSource(n) and result = "SOURCE")
  or
  (TestFlow::flowTo(n) and result = "reached")
  or
  (TestFlow2::flow(n, _) and result = "rev")
  or
  (TestConfiguration2::isSink(n) and result = "SINK")
}

from DataFlow::Node n
where n.getLocation().getFile().getBaseName() = "swiftui.swift"
select
  concat(n.getLocation().toString(), ", "),
  concat(n.toString(), ", "),
  strictconcat(describe(n), ", ")
