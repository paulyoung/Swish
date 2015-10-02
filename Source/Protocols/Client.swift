import Foundation
import Argo
import Result

public protocol Client {
  var requestPerformer: RequestPerformer { get }

  func performRequest<T: Request>(request: T, completionHandler: Result<T.ResponseType, NSError> -> ())
}

public extension Client {
  func performRequest<T: Request>(request: T, completionHandler: Result<T.ResponseType, NSError> -> Void) {
    requestPerformer.performRequest(request.build()) { result in
      let object = result >>- deserialize >>- { request.parse($0) }
      dispatch_async(dispatch_get_main_queue()) { completionHandler(object) }
    }
  }
}

private func deserialize(response: HTTPResponse) -> Result<JSON, NSError> {
  switch response.code {
  case 200...299:
    return parseJSON(response)
  case 300...399:
    return .Failure(Result<JSON, NSError>.error("Multiple choices: \(response.code)"))
  case 400...499:
    return .Failure(Result<JSON, NSError>.error("Bad request: \(response.code)"))
  case 500...599:
    return .Failure(Result<JSON, NSError>.error("Server error: \(response.code)"))
  default:
    return .Failure(Result<JSON, NSError>.error("Unknown error: \(response.code)"))
  }
}

private func parseJSON(response: HTTPResponse) -> Result<JSON, NSError> {
  guard let data = response.data else {
    return .Success(JSON.Null)
  }

  do {
    let object = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0))
    return .Success(JSON.parse(object))
  } catch let error as NSError {
    return .Failure(error)
  }
}
