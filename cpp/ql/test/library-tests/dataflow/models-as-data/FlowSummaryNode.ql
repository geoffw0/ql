import testModels
private import semmle.code.cpp.ir.dataflow.internal.DataFlowPrivate
private import semmle.code.cpp.ir.dataflow.internal.DataFlowUtil

string describe(DataFlow::Node n) {
  n instanceof ParameterNode and result = "ParameterNode"
  or
  n instanceof PostUpdateNode and result = "PostUpdateNode"
  or
  n instanceof ArgumentNode and result = "ArgumentNode"
  or
  n instanceof ReturnNode and result = "ReturnNode"
  or
  n instanceof OutNode and result = "OutNode"
}

//from FlowSummaryNode n
//select n, concat(describe(n), ", "), concat(n.getSummarizedCallable().toString(), ", "), concat(n.getEnclosingCallable().toString(), ", ")

private import semmle.code.cpp.dataflow.internal.FlowSummaryImpl as FlowSummaryImpl

//from FlowSummaryImpl::Public::SummarizedCallable c
//select c

// ArgumentNode, FlowSummaryNode
/*from SummaryCall call_, ArgumentPosition pos_, FlowSummaryNode n
where
  FlowSummaryImpl::Private::summaryArgumentNode(call_.getReceiver(), n.getSummaryNode(), pos_)
select
  call_, pos_, n
*/

/*from FlowSummaryImpl::Private::SummaryNode receiver, FlowSummaryImpl::Private::SummaryNode arg, ArgumentPosition pos
where
  FlowSummaryImpl::Private::summaryArgumentNode(receiver, arg, pos)
select
  receiver, arg, pos*/
//!!! this yields no results, thus we get no SummaryArgumentNodes in the database; presumably it yields no results
//    because we're not defining something we should be for the shared library to work !!!

// ---

//from FlowSummaryImpl::Public::SummarizedCallable callable, FlowSummaryImpl::Private::SummaryComponentStack s, FlowSummaryImpl::Private::SummaryNode receiver, FlowSummaryImpl::Private::SummaryNode arg, ArgumentPosition pos
//where arg = FlowSummaryImpl::Private::summaryNodeOutputState(callable, s)
//select callable, s, receiver, pos // --- has results

//from FlowSummaryImpl::Public::SummarizedCallable callable, FlowSummaryImpl::Private::SummaryComponentStack s, FlowSummaryImpl::Private::SummaryNode receiver, FlowSummaryImpl::Private::SummaryNode arg, ArgumentPosition pos
//where FlowSummaryImpl::Private::callbackInput(callable, s, receiver, pos)
//select callable, s, receiver, pos // --- none

// ---

//from FlowSummaryImpl::Public::SummarizedCallable c, FlowSummaryImpl::Private::SummaryComponentStack s, ArgumentPosition pos
//where any(FlowSummaryImpl::Private::SummaryNodeState state).isOutputState(c, s)
//select c, s, pos // --- has results

//from FlowSummaryImpl::Private::SummaryComponentStack s, ArgumentPosition pos
//where s.head() = FlowSummaryImpl::Private::TParameterSummaryComponent(pos)
//select s, pos // --- has results

//from FlowSummaryImpl::Public::SummarizedCallable c, FlowSummaryImpl::Private::SummaryComponentStack s, FlowSummaryImpl::Private::SummaryNode receiver, ArgumentPosition pos
//where receiver = FlowSummaryImpl::Private::summaryNodeInputState(c, s.tail())
//select c, s, receiver, pos // --- no results / no results
from FlowSummaryImpl::Public::SummarizedCallable c, FlowSummaryImpl::Private::SummaryComponentStack s, FlowSummaryImpl::Private::SummaryNode receiver, ArgumentPosition pos
where receiver = FlowSummaryImpl::Private::summaryNodeInputState(c, s)
select c, s, receiver, pos, count(FlowSummaryImpl::Private::SummaryComponentStack sp | sp.tail() = s)
// --- result only with count = 0
// so the issue is that the stack nodes aren't children of something...
// - this is a trail for ArgumentNode's existing, to be specific
// - so does that mean we have the function but not the argument at this level; or
//   the function and argument aren't associated perhaps?
// FUNCTION myfoo -> Argument 'x'
// - in the results, s *is* a an argument, so we're missing
//   the function-argument association I think.

// ---

/*from FlowSummaryImpl::Private::SummaryNode r, FlowSummaryImpl::Public::SummarizedCallable c, FlowSummaryImpl::Private::SummaryComponentStack s, FlowSummaryImpl::Private::SummaryNodeState state
where state.isInputState(c, s) and
  (
    r = FlowSummaryImpl::Private::TSummaryInternalNode(c, state) // no results
  )
select r, c, s, state
// OR
*//*
from FlowSummaryImpl::Private::SummaryNode r, FlowSummaryImpl::Public::SummarizedCallable c, FlowSummaryImpl::Private::SummaryComponentStack s, FlowSummaryImpl::Private::SummaryNodeState state
where state.isInputState(c, s) and
  (
    exists(ParameterPosition pos |
      FlowSummaryImpl::Private::parameterReadState(c, state, pos) and
      r = FlowSummaryImpl::Private::TSummaryParameterNode(c, pos)
    )
  )
select r, c, s, state // has results (they why doesn't summaryNodeInputState?
*/
