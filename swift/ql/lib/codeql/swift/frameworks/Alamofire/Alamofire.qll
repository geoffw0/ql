/**
 * Models for the Alamofire networking library.
 */

import swift
private import codeql.swift.dataflow.DataFlow
private import codeql.swift.dataflow.ExternalFlow
private import codeql.swift.dataflow.FlowSources

/**
 * An Alamofire response handler type.
 */
private class AlamofireResponseType extends NominalTypeDecl {
  AlamofireResponseType() {
    this.getFullName() = ["DataResponse", "DownloadResponse"] or
    this.getABaseTypeDecl() instanceof AlamofireResponseType
  }

  /**
   * A response handler field that contains remote data.
   */
  FieldDecl getADataField() {
    result = this.getAMember() and
    result.getName() = ["data", "value", "result"]
  }
}

/**
 * A remote flow source that is an access to remote data from an Alamofire response handler.
 */
private class AlamofireResponseSource extends RemoteFlowSource {
  AlamofireResponseSource() {
    exists(AlamofireResponseType responseType |
      this.asExpr().(MemberRefExpr).getMember() = responseType.getADataField()
    )
  }

  override string getSourceType() { result = "Data from an Alamofire response" }
}


/**
 * A method such as `DataRequest.responseString`, that registers a response handler.
 */
/*private class AlamofireDataRequestResponse extends MethodDecl {
  AlamofireDataRequestResponse() {
    exists(string fName |
      this.hasQualifiedName(["DataRequest", "DataStreamRequest", "DownloadRequest"], fName) and
      fName.matches("response%")
    )
  }
*/
  /**
   * Gets an expression that is a `completionHandler` for a call to this method.
   */
  /*Expr getACompletionHandlerExpr() {
    exists(CallExpr call |
      this = call.getStaticTarget() and
      result = call.getArgumentWithLabel(["completionHandler", "stream"]).getExpr()
    )
  }
*/
  /**
   * Gets a `Callable` (function / closure) that is a `completionHandler` for
   * a call to this method.
   */
  /*Callable getACompletionHandler() {
    // TODO: is there / create a generic way to do this?
    // TODO: use local dataflow to connect more results.
    result = getACompletionHandlerExpr().(CallExpr).getStaticTarget() or
    result = getACompletionHandlerExpr().(ClosureExpr)
  }
}*/

/*
 * private class AlamofireCompletionHandlerSource extends RemoteFlowSource {
 *  AlamofireCompletionHandlerSource() {
 *    exists(AlamofireDataRequestResponse r |
 *      this.(DataFlow::ParameterNode).getParameter() = r.getACompletionHandler().getAParam()
 *    )
 *  }
 *
 *  override string getSourceType() {
 *    result = "Data from an Alamofire completionHandler"
 *  }
 * }
 */

/**
 * An Alamofire response handler type.
 */
/*private*/ class AlamofireResponseStreamType extends NominalTypeDecl {
  AlamofireResponseStreamType() {
    this.getFullName() = "DataStreamRequest.Stream" or
    this.getABaseTypeDecl() instanceof AlamofireResponseStreamType
  }

  /**
   * A response handler field that contains remote data.
   */
/*  FieldDecl getADataField() {
    result = this.getAMember() and
    result.getName() = ["data", "value", "result"]
  }*/
}

/**
 * A remote flow source that is an access to a remote data from an Alamofire response stream handler.
 */
/*private*/ class AlamofireResponseStreamSource extends RemoteFlowSource {
  AlamofireResponseStreamSource() {
    // DataStreamRequest.Stream.event.stream(result).success(data)
    /*
     * exists(AlamofireResponseType responseType, FieldDecl eventField, EnumCaseDecl streamCase
     *       |
     *      eventField = responseType.getAMember() and
     *      eventField.getName() = "event" and
     *      //this.asExpr().(MemberRefExpr).getMember() = eventField and
     *      t
     * //      streamCase = eventField.(EnumDecl)
     *    )
     */

    //  case let .stream(result):
    //case let .success(value):
    /*
     *    exists(EnumElementPattern successEnum |
     *      successEnum.getElement().getName() = "success" and
     *      this.asDefinition() = successEnum
     *    )
     */

    exists(CaseStmt cs, EnumElementDecl e |
      cs.getALabel().getPattern().(BindingPattern).getSubPattern().(EnumElementPattern).getElement() = e and
      // TODO: ^ what other ways can EnumElementPattern be used.
      e.getName() = "stream" and //"success" and // TODO: check context of e
      this.asExpr() = cs.getAVariable().getAnAccess() // TODO: .asDefinition() = cs.getAVariable()
      //this.asExpr() = cs.getAVariable()
    )
  }

  override string getSourceType() { result = "Data from an Alamofire response stream" }
}
//    this instanceof TypeAliasDecl
//    this.(TypeAliasDecl).
// result.success field
/*
 * exists(FieldDecl mid |
 *      mid = this.getAMember() and
 *      mid.getName() = "result" and
 *      result = mid.get and
 *      result.getName() = "success"
 *    )
 */

/*
 *    exists(FieldDecl event, EnumCaseDecl stream |
 *      event = this.getAMember() and
 *      event.getName() = "event" and
 * //      result = event
 *      stream
 *    )
 */

/*
 * final class DataStreamRequest: Request {
 *  typealias Handler<Success, Failure: Error> = (Stream<Success, Failure>) throws -> Void
 *
 *  struct Stream<Success, Failure: Error> {
 *      let event: Event<Success, Failure>
 *  }
 *
 *  enum Event<Success, Failure: Error> {
 *      case stream(Result<Success, Failure>)
 *      case complete(Completion)
 *  }
 *
 *  struct Completion {
 *  }
 * }
 */
