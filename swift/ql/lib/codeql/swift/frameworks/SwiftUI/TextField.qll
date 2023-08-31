/**
 * Provides models for the `TextField` and related SwiftUI classes.
 */

import swift
private import codeql.swift.dataflow.DataFlow
private import codeql.swift.dataflow.ExternalFlow
private import codeql.swift.dataflow.FlowSources
private import codeql.swift.dataflow.FlowSteps

/**
 * TODO
 */
class TextFieldFlowSource extends LocalFlowSource {
  TextFieldFlowSource() {
    exists(CallExpr call, MemberRefExpr callRef, MemberRefExpr accessRef |
      // `callRef` is the `text` argument to `TextField` or similar
      // TODO: alternative models here
      call.getStaticTarget().(Method).hasQualifiedName("TextField", "init(_:text:)") and
      call.getArgument(1).getExpr() = callRef and
      // `callRef` is the
      //callRef.getBase().getType().getName() = "Binding" and
      // TODO: bases should match
      // TODO: don't hardcode string "input"
      callRef.getMember().(VarDecl).getName() = "$input" and
      accessRef.getMember().(VarDecl).getName() = "input" and
      accessRef = this.asExpr()
    )
  }
  // TODO: can we turn this into a general purpose taint step for
  // property wrappers?
  PLAN:
  1. write a dataflow test for a property wrapper that has nothing
  to do with SwiftUI.

  @propertyWrapper
  struct MyPropertyWrapper {
    private var actualValue: Int
    private var projectedValue: Int

    var wrappedValue: Int {
      get { return actualValue + projectedValue}
      set { actualValue = newValue }
    }
    init() {
      actualValue = 0
      projectedValue = 0
    }
    init(wrappedValue: Int) {
      actualValue = wrappedValue
    }
    init(wrappedValue: Int, projectedValue: Int) {
      self.actualValue = wrappedValue
      self.projectedValue = projectedValue
    }
  }

  struct test {
    @MyPropertyWrapper v1: Int
    @MyPropertyWrapper v2: Int = source()
    @MyPropertyWrapper(wrappedValue: source()) v3: Int
    @MyPropertyWrapper(wrappedValue: source(), discarded: 0) v4: Int
    @MyPropertyWrapper(wrappedValue: 0, projectedValue: source()) v5: Int
    @MyPropertyWrapper(projectedValue: 0) v6: Int = source()
    @MyPropertyWrapper v7: Int

    func doTest() {
      v1 = source()
      $v7 = source() // $v7 is v7.projectedValue

      sink(arg: v1) // $ tainted=?
      sink(arg: $v1)
      sink(arg: v2) // $ tainted=?
      sink(arg: $v2)
      sink(arg: v3) // $ tainted=?
      sink(arg: $v3)
      sink(arg: v4) // $ tainted=?
      sink(arg: $v4)
      sink(arg: v5) // $ tainted=?
      sink(arg: $v5) // $ tainted=?
      sink(arg: v6) // $ tainted=?
      sink(arg: $v6)
      sink(arg: v7) // $ tainted=?
      sink(arg: $v7) // $ tainted=?
    }
  }


/*
  2. do what I can to model taint there; this will be valuable
      ^^^ better still, do a draft PR of just the property wrappers
      test and talk to Robert about it.
  3. return to this, if I can make the TextField taint source
     simple, if I can't make it figure out the binding like in
     the code I wrote above (which just about works).
*/

  override string getSourceType() { result = "TODO" }
}


/*
 * A read of `UIApplication.LaunchOptionsKey.url` on a dictionary received in
 * `UIApplicationDelegate.application(_:didFinishLaunchingWithOptions:)` or
 * `UIApplicationDelegate.application(_:willFinishLaunchingWithOptions:)`.
 */
/*private class UrlLaunchOptionsRemoteFlowSource extends RemoteFlowSource {
  UrlLaunchOptionsRemoteFlowSource() {
    exists(ApplicationWithLaunchOptionsFunc f, SubscriptExpr e |
      DataFlow::localExprFlow(f.getParam(1).getAnAccess(), e.getBase()) and
      e.getAnArgument().getExpr().(MemberRefExpr).getMember() instanceof LaunchOptionsUrlVarDecl and
      this.asExpr() = e
    )
  }

  override string getSourceType() {
    result = "Remote URL in UIApplicationDelegate.application.launchOptions"
  }
}*/

/*
 * A model for `TextField` and related class members that are flow sources.
 */
/*private class TextFieldSource extends SourceModelCsv {
  override predicate row(string row) {
    row =
      [
//shortcut for now (reaches sink):
//        ";State;true;wrappedValue;;;;local",

// nope:
//";Binding;true;wrappedValue;;;;local",

// taints a few random non-located self nodes
//        ";MyStruct;true;_input;;;;local",
 //       ";MyStruct;true;_input.wrappedValue;;;;local",

// doesn't reach sink:
//";State;true;get;;;ReturnValue;local",
//";State;true;get();;;ReturnValue;local",
//";State;true;;;;;local",

//        ";State;true;projectedValue;;;;local",
//        ";State;true;;;;;local",

//taint source: TextField.init arg
          ";TextField;true;init(_:text:);;;Argument[1];local",
          //";TextField;true;init(_:text:);;;Argument[1].PostUpdate;local",

          ";TextField;true;init(_:text:);;;Argument[1].Field[_input];local",
          ";TextField;true;init(_:text:);;;Argument[1].Field[_input].Field[wrappedValue];local",
          ";TextField;true;init(_:text:);;;Argument[1]._input;local",
          ";TextField;true;init(_:text:);;;Argument[1]._input.wrappedValue;local",


//          ";Binding;true;;;;;local",
//          ";Binding;true;get();;;Argument[0];local",
//          ";Binding;true;get();;;Argument[0].PostUpdate;local",

]
  }
}*/



/**
 * A model for `TextField` and related class members members that permit taint flow.
 */
private class TextFieldSummaries extends SummaryModelCsv {
  override predicate row(string row) {
    row = [
        ";MyStruct;true;get();;;Argument[-1].$input;ReturnValue;taint",
        ";MyStruct;true;get();;;Argument[-1].Field[$input];ReturnValue;taint",
        ";State;true;;;;projectedValue;wrappedValue;taint",
        ";State;true;set(_:);;;Argument[0];Argument[-1];taint",
        ";State;true;set(_:);;;Argument[0];Argument[-1].wrappedValue;taint",
        ";State;true;?;;;?;wrappedValue;taint",
  //
  ";TextField;true;init(_:text:);;;Argument[1].PostUpdate;Argument[1];taint",

  ";TextField;true;init(_:text:);;;Argument[1];Argument[-1]._input;taint",
  ";TextField;true;init(_:text:);;;Argument[1];Argument[-1].Field[_input];taint",
  ";TextField;true;init(_:text:);;;Argument[1];Argument[-1]._input.wrappedValue;taint",
  ";TextField;true;init(_:text:);;;Argument[1];Argument[-1].Field[_input].Field[wrappedValue];taint",
  ";TextField;true;init(_:text:);;;Argument[1].PostUpdate;Argument[-1]._input;taint",
  ";TextField;true;init(_:text:);;;Argument[1].PostUpdate;Argument[-1].Field[_input];taint",
  ";TextField;true;init(_:text:);;;Argument[1].PostUpdate;Argument[-1]._input.wrappedValue;taint",
  ";TextField;true;init(_:text:);;;Argument[1].PostUpdate;Argument[-1].Field[_input].Field[wrappedValue];ltaintocal",

        ";State;true;get;;;Argument[-1].projectedValue;ReturnValue;taint",
        ";State;true;get();;;Argument[-1].projectedValue;ReturnValue;taint",
        ";State;true;get;;;Argument[-1].Field[projectedValue];ReturnValue;taint",
        ";State;true;get();;;Argument[-1].Field[projectedValue];ReturnValue;taint",

        ";TextField;true;init(_:text:);;;Argument[1];Argument[-1];taint",
        ";TextField;true;init(_:text:);;;Argument[1];Argument[-1]._input.wrappedValue;taint",
/*
        TODO: I think I need a low level dataflow step
        for projectedValue -> wrappedValue (or something
          like that) on a State.
        Or something like that on a Binding, maybe.*/
      ]
  }
}

/**
 * A content implying that, if a `State` is tainted, then its `wrappedValue` is also tainted.
 */
private class StateFieldsInheritTaint extends TaintInheritingContent,
  DataFlow::Content::FieldContent
{
  StateFieldsInheritTaint() {
    this.getField().hasQualifiedName("State", "wrappedValue")
    or
    this.getField().hasQualifiedName("State", "projectedValue")
or
this.getField().hasQualifiedName("MyStruct", "input")
or
this.getField().hasQualifiedName("MyStruct", "$input")
or
this.getField().hasQualifiedName("State", "input")
or
this.getField().hasQualifiedName("State", "$input")
  }
}
