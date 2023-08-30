import swift
import TestUtilities.InlineExpectationsTest
import FlowConfig
import codeql.swift.dataflow.TaintTracking
import codeql.swift.dataflow.DataFlow

//private import codeql.swift.controlflow.internal.ControlFlowElements

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

/*  predicate isAdditionalFlowStep(DataFlow::Node node1, DataFlow::Node node2) {
    exists(Type t |
      node1.asExpr().(MemberRefExpr).getBase().getType() = t and
      node1.asExpr().(MemberRefExpr).getMember().(VarDecl).getName() = "$input" and
      node2.asExpr().(MemberRefExpr).getBase().getType() = t and
      node2.asExpr().(MemberRefExpr).getMember().(VarDecl).getName() = "input"
    )
  }*/
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

module TestFlow2 = TaintTracking::Global<TestConfiguration2>;

module TestConfiguration3 implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node src) { src instanceof FlowSource }

  predicate isSink(DataFlow::Node sink) {
    exists(CallExpr sinkCall |
      sinkCall.getStaticTarget().getName().matches("sink%") and
      sinkCall.getAnArgument().getExpr() = sink.asExpr()
    )
  }
}

module TestFlow3 = TaintTracking::Global<TestConfiguration3>;

int explorationLimit() { result = 100 }

module PartialFlow = TestFlow3::FlowExploration<explorationLimit/0>;

string describe(DataFlow::Node n) {
  (TestConfiguration::isSource(n) and result = "SOURCE")
  or
  (TestFlow::flowTo(n) and result = "reached")
  or
  (TestFlow2::flow(n, _) and result = "rev")
  or
  (TestConfiguration2::isSink(n) and result = "SINK")
  or exists(PartialFlow::PartialPathNode sink |
    PartialFlow::partialFlow(_, sink, _) and
    sink.getNode() = n and
    result = "partial"
  )
}

string describe2(DataFlow::Node n) {
  exists(CallExpr ce, int i |
    ce.getArgument(i).getExpr() = n.asExpr() and
    result = ce.getStaticTarget().getName() + "arg" + i.toString()
  ) or
  result = "ql:" + n.asExpr().getAQlClass() or
  result = "type:" + n.asExpr().getType().toString() or
  result = "type.ql:" + n.asExpr().getType().getAQlClass() or
  result = "post." + describe(n.(DataFlow::PostUpdateNode).getPreUpdateNode()) or
  result = "post." + describe2(n.(DataFlow::PostUpdateNode).getPreUpdateNode())
}

from DataFlow::Node n
where n.getLocation().getFile().getBaseName() = "swiftui.swift"
and
(
  exists(describe(n)) or
n.getLocation().getStartLine() = [74, 75, 76] or
n.asExpr().(MemberRefExpr).getMember().(VarDecl).getName() = ["wrappedValue", "projectedValue", "input", "$input", "_input"]
)
select
  concat(n.getLocation().getStartLine().toString() + ":" + n.getLocation().getStartColumn().toString(), ", "),
  concat(n.toString(), ", "),
  concat(describe(n), ", "),
  concat(describe2(n), ", ")
