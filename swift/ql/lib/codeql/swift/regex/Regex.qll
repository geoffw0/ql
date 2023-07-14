/**
 * Provides classes and predicates for reasoning about regular expressions.
 */

import swift
import codeql.swift.regex.RegexTreeView
private import codeql.swift.dataflow.DataFlow
private import internal.ParseRegex
private import internal.RegexTracking

/**
 * A string literal that is used as a regular expression. For example
 * the string literal `"(a|b).*"` in:
 * ```
 * Regex("(a|b).*").firstMatch(in: myString)
 * ```
 */
private class ParsedStringRegex extends RegExp, StringLiteralExpr {
  DataFlow::Node use;

  ParsedStringRegex() { StringLiteralUseFlow::flow(DataFlow::exprNode(this), use) }

  /**
   * Gets a dataflow node where this string literal is used as a regular
   * expression.
   */
  DataFlow::Node getUse() { result = use }
}

/**
 * A data-flow node where a regular expression object is created.
 */
abstract class RegexCreation extends DataFlow::Node {
  /**
   * Gets a dataflow node for the string that the regular expression object is
   * created from.
   */
  abstract DataFlow::Node getStringInput();
}

/**
 * A data-flow node where a `Regex` or `NSRegularExpression` object is created.
 */
private class StandardRegexCreation extends RegexCreation {
  DataFlow::Node input;

  StandardRegexCreation() {
    exists(CallExpr call |
      (
        call.getStaticTarget().(Method).hasQualifiedName("Regex", ["init(_:)", "init(_:as:)"]) or
        call.getStaticTarget()
            .(Method)
            .hasQualifiedName("NSRegularExpression", "init(pattern:options:)")
      ) and
      input.asExpr() = call.getArgument(0).getExpr() and
      this.asExpr() = call
    )
  }

  override DataFlow::Node getStringInput() { result = input }
}

newtype TRegexParseMode =
  MkIgnoreCase() or // case insensitive
  MkVerbose() or // ignores whitespace and `#` comments within patterns
  MkDotAll() or // dot matches all characters, including line terminators
  MkMultiLine() or // `^` and `$` also match beginning and end of lines
  MkUnicode() // Unicode UAX 29 word boundary mode

class RegexParseMode extends TRegexParseMode {
  string toString() {
    (this = MkIgnoreCase() and result = "IGNORECASE") or
    (this = MkVerbose() and result = "VERBOSE") or
    (this = MkDotAll() and result = "DOTALL") or
    (this = MkUnicode() and result = "MULTILINE") or
    (this = MkIgnoreCase() and result = "UNICODE")
  }
}

/**
 * A unit class for adding additional flow steps for regular expressions.
 */
class RegexAdditionalFlowStep extends Unit {
  /**
   * Holds if the step from `node1` to `node2` should be considered a flow
   * step for regular expressions.
   */
  abstract predicate step(DataFlow::Node nodeFrom, DataFlow::Node nodeTo);

  /**
   * Holds if the step from `node1` to `node2` either sets (`isSet` = true)
   * or unsets (`isSet` = false) parse mode `mode` for the regular expression.
   */
  abstract predicate modifiesParseMode(DataFlow::Node nodeFrom, DataFlow::Node nodeTo, RegexParseMode mode, boolean isSet);
}

/**
 * An additional flow step for `Regex` or `NSRegularExpression`.
 */
class StandardRegexAdditionalFlowStep extends RegexAdditionalFlowStep {
  override predicate step(DataFlow::Node nodeFrom, DataFlow::Node nodeTo) {
    this.modifiesParseMode(nodeFrom, nodeTo, _, _)
  }

  override predicate modifiesParseMode(DataFlow::Node nodeFrom, DataFlow::Node nodeTo, RegexParseMode mode, boolean isSet)
  {
    exists(CallExpr ce |
      ce.getStaticTarget().(Method).hasQualifiedName("Regex", "dotMatchesNewlines(_:)") and
      nodeFrom.asExpr() = ce.getQualifier() and
      nodeTo.asExpr() = ce and
      mode = MkDotAll() and
      // TODO: other methods
      // decode the value being set
      if ce.getArgument(0).getExpr().(BooleanLiteralExpr).getValue() = false then
        isSet = false // mode is set to false
      else
        isSet = true // mode is set to true OR mode is set to default (=true) OR mode is set to an unknown value
    )
  }
}

/**
 * A call that evaluates a regular expression. For example, the call to `firstMatch` in:
 * ```
 * Regex("(a|b).*").firstMatch(in: myString)
 * ```
 */
abstract class RegexEval extends CallExpr {
  /**
   * Gets the input to this call that is the regular expression being evaluated. This may
   * be a regular expression object or a string literal.
   */
  abstract Expr getRegexInput();

  /**
   * Gets the input to this call that is the string the regular expression is evaluated on.
   */
  abstract Expr getStringInput();

  /**
   * Gets a regular expression value that is evaluated here (if any can be identified).
   */
  RegExp getARegex() {
    // string literal used directly as a regex
    result.(ParsedStringRegex).getUse().asExpr() = this.getRegexInput()
    or
    // string literal -> regex object -> use
    exists(RegexCreation regexCreation |
      result.(ParsedStringRegex).getUse() = regexCreation.getStringInput() and
      RegexUseFlow::flow(regexCreation, DataFlow::exprNode(this.getRegexInput()))
    )
  }
}

/**
 * A call to a function that always evaluates a regular expression.
 */
private class AlwaysRegexEval extends RegexEval {
  Expr regexInput;
  Expr stringInput;

  AlwaysRegexEval() {
    this.getStaticTarget()
        .(Method)
        .hasQualifiedName("Regex", ["firstMatch(in:)", "prefixMatch(in:)", "wholeMatch(in:)"]) and
    regexInput = this.getQualifier() and
    stringInput = this.getArgument(0).getExpr()
    or
    this.getStaticTarget()
        .(Method)
        .hasQualifiedName("NSRegularExpression",
          [
            "numberOfMatches(in:options:range:)", "enumerateMatches(in:options:range:using:)",
            "matches(in:options:range:)", "firstMatch(in:options:range:)",
            "rangeOfFirstMatch(in:options:range:)",
            "replaceMatches(in:options:range:withTemplate:)",
            "stringByReplacingMatches(in:options:range:withTemplate:)"
          ]) and
    regexInput = this.getQualifier() and
    stringInput = this.getArgument(0).getExpr()
    or
    this.getStaticTarget()
        .(Method)
        .hasQualifiedName("BidirectionalCollection",
          [
            "contains(_:)", "firstMatch(of:)", "firstRange(of:)", "matches(of:)",
            "prefixMatch(of:)", "ranges(of:)",
            "split(separator:maxSplits:omittingEmptySubsequences:)", "starts(with:)",
            "trimmingPrefix(_:)", "wholeMatch(of:)"
          ]) and
    regexInput = this.getArgument(0).getExpr() and
    stringInput = this.getQualifier()
    or
    this.getStaticTarget()
        .(Method)
        .hasQualifiedName("RangeReplaceableCollection",
          [
            "replace(_:maxReplacements:with:)", "replace(_:with:maxReplacements:)",
            "replacing(_:maxReplacements:with:)", "replacing(_:subrange:maxReplacements:with:)",
            "replacing(_:with:maxReplacements:)", "replacing(_:with:subrange:maxReplacements:)",
            "trimPrefix(_:)"
          ]) and
    regexInput = this.getArgument(0).getExpr() and
    stringInput = this.getQualifier()
  }

  override Expr getRegexInput() { result = regexInput }

  override Expr getStringInput() { result = stringInput }
}
