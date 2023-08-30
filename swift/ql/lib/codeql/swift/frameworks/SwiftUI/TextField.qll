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
}



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
