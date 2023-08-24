/**
 * Provides models for the `TextField` and related SwiftUI classes.
 */

import swift
private import codeql.swift.dataflow.DataFlow
private import codeql.swift.dataflow.ExternalFlow
private import codeql.swift.dataflow.FlowSteps

/**
 * A model for `TextField` and related class members that are flow sources.
 */
private class TextFieldSource extends SourceModelCsv {
  override predicate row(string row) {
    row =
      [
//shortcut for now (reaches sink):
//        ";State;true;wrappedValue;;;;local",

// doesn't reach sink:
//";State;true;get;;;ReturnValue;local",
//";State;true;get();;;ReturnValue;local",
//";State;true;;;;;local",


//        ";State;true;projectedValue;;;;local",
//        ";State;true;;;;;local",

//taint source: TextField.init arg
          ";TextField;true;init(_:text:);;;Argument[1];local",
      ]
  }
}



/**
 * A model for `TextField` and related class members members that permit taint flow.
 */
private class TextFieldSummaries extends SummaryModelCsv {
  override predicate row(string row) {
none()/*    row = [
        ";State;true;get;;;Argument[-1].projectedValue;ReturnValue;taint",
        ";State;true;get();;;Argument[-1].projectedValue;ReturnValue;taint",
      ]*/
  }
}

/**
 * A content implying that, if a `State` is tainted, then its `wrappedValue` is also tainted.
 */
private class StateFieldsInheritTaint extends TaintInheritingContent,
  DataFlow::Content::FieldContent
{
  StateFieldsInheritTaint() {
none()/*    this.getField().hasQualifiedName("State", "wrappedValue")
    or
    this.getField().hasQualifiedName("State", "projectedValue")
*//*or
this.getField().hasQualifiedName("MyStruct", "input")
or
this.getField().hasQualifiedName("MyStruct", "$input")
or
this.getField().hasQualifiedName("State", "input")
or
this.getField().hasQualifiedName("State", "$input")*/
  }
}
