/**
 * Provides models for the `TextField` and related SwiftUI classes.
 */

import swift
private import codeql.swift.dataflow.ExternalFlow

/**
 * A model for `TextField`, `SecureTextField` and `TextEditor` members that are flow sources.
 */
private class UITextFieldSource extends SourceModelCsv {
  override predicate row(string row) {
    row =
      [
      ";State;true;wrappedValue;;;;local",
      ]
  }
}
