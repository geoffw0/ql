/**
 * Provides a taint-tracking configuration for reasoning about unsafe
 * deserialization.
 */

import swift
private import codeql.swift.dataflow.DataFlow
private import codeql.swift.dataflow.FlowSources
private import codeql.swift.dataflow.TaintTracking
private import codeql.swift.security.UnsafeDeserializationExtensions

/**
 * A taint-tracking configuration for unsafe deserialization vulnerabilities.
 */
module UnsafeDeserializationConfig implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node source) { source instanceof RemoteFlowSource }

  predicate isSink(DataFlow::Node sink) { sink instanceof UnsafeDeserializationSink }

  predicate isBarrier(DataFlow::Node barrier) { barrier instanceof UnsafeDeserializationBarrier }

  predicate isAdditionalFlowStep(DataFlow::Node n1, DataFlow::Node n2) {
    any(UnsafeDeserializationAdditionalFlowStep s).step(n1, n2)
  }
}

/**
 * Taint flow for unsafe deserialization vulnerabilities.
 */
module UnsafeDeserializationFlow = TaintTracking::Global<UnsafeDeserializationConfig>;
