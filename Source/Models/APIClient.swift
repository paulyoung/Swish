import Foundation
import Argo
import Result

public struct APIClient: Client {
  public let requestPerformer: RequestPerformer

  public init(requestPerformer: RequestPerformer = NetworkRequestPerformer()) {
    self.requestPerformer = requestPerformer
  }
}
