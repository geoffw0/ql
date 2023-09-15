/**
 * Provides classes and predicates to reason about unsafe deserialization
 * vulnerabilities.
 */

import swift
private import codeql.swift.dataflow.DataFlow
private import codeql.swift.dataflow.ExternalFlow

/**
 * A data flow sink for unsafe deserialization vulnerabilities.
 */
abstract class UnsafeDeserializationSink extends DataFlow::Node { }

/**
 * A barrier for unsafe deserialization vulnerabilities
 */
abstract class UnsafeDeserializationBarrier extends DataFlow::Node { }

/**
 * A unit class for adding additional flow steps.
 */
class UnsafeDeserializationAdditionalFlowStep extends Unit {
  /**
   * Holds if the step from `node1` to `node2` should be considered a flow
   * step for paths related to unsafe deserialization vulnerabilities.
   */
  abstract predicate step(DataFlow::Node n1, DataFlow::Node n2);
}

/**
 * A sink defined in a CSV model.
 */
private class DefaultUnsafeDeserializationSink extends UnsafeDeserializationSink {
  DefaultUnsafeDeserializationSink() { sinkNode(this, "unsafe-deserialization") }
}

private class UnsafeWebViewFetchSinks extends SinkModelCsv {
  override predicate row(string row) {
    row =
      [
        // PropertyListSerialization
        ";PropertyListDecoder;true;decode(_:from:);;;Argument[1];unsafe-deserialization",
        ";PropertyListDecoder;true;decode(_:from:format:);;;Argument[1];unsafe-deserialization",
        ";PropertyListDecoder;true;decode(_:from:configuration:);;;Argument[1];unsafe-deserialization",
        ";PropertyListDecoder;true;decode(_:from:format:configuration:);;;Argument[1];unsafe-deserialization",
        // JSONSerialization
        ";JSONDecoder;true;decode(_:from:);;;Argument[1];unsafe-deserialization",
        ";JSONDecoder;true;decode(_:from:configuration:);;;Argument[1];unsafe-deserialization",
        // Yams library (YAML)
        ";YAMLDecoder;true;decode(_:from:);;;Argument[1];unsafe-deserialization",
        ";YAMLDecoder;true;decode(_:from:userInfo:);;;Argument[1];unsafe-deserialization",
      ]
  }
}
