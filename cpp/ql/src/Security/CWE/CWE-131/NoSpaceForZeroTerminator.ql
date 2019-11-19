/**
 * @name No space for zero terminator
 * @description Allocating a buffer using 'malloc' without ensuring that
 *              there is always space for the entire string and a zero
 *              terminator can cause a buffer overrun.
 * @kind problem
 * @problem.severity error
 * @precision high
 * @id cpp/no-space-for-terminator
 * @tags reliability
 *       security
 *       external/cwe/cwe-131
 *       external/cwe/cwe-120
 *       external/cwe/cwe-122
 */

import cpp
import semmle.code.cpp.dataflow.DataFlow
import semmle.code.cpp.models.interfaces.ArrayFunction

class MallocCall extends FunctionCall {
  MallocCall() { this.getTarget().hasGlobalOrStdName("malloc") }

  Expr getAllocatedSize() {
    result = this.getArgument(0)
  }
}

predicate terminationProblem(MallocCall malloc, string msg) {
  // malloc(strlen(...))
  exists(StrlenCall strlen |
    DataFlow::localExprFlow(strlen, malloc.getAllocatedSize())
  ) and
  // flows to somewhere that implies it's a null-terminated string
  exists(FunctionCall fc, int arg |
    DataFlow::localExprFlow(malloc, fc.getArgument(arg)) and
    (
      // flows into null terminated string argument
      fc.getTarget().(ArrayFunction).hasArrayWithNullTerminator(arg)
      or
      // flows into likely null terminated string argument (such as `strcpy`, `strcat`)
      fc.getTarget().(ArrayFunction).hasArrayWithUnknownSize(arg)
      or
      // flows into string argument to a formatting function (such as `printf`)
      exists(int n, Type t |
        fc.(FormattingFunctionCall).getConversionArgument(n) = fc.getArgument(arg) and
        fc.(FormattingFunctionCall).getFormat().(FormatLiteral).getConversionType(n) = t and
        t.getUnspecifiedType() instanceof PointerType and // `%s`, `%ws` etc
        not t.getUnspecifiedType() instanceof VoidPointerType // but not `%p`
      )
    )
  ) and
  msg = "This allocation does not include space to null-terminate the string."
}

from Expr problem, string msg
where terminationProblem(problem, msg)
select problem, msg
