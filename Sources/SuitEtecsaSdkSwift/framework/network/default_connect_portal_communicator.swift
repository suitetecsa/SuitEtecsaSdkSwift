import Foundation

public class DefaultConnectPortalCommunicator: ConnectPortalCommunicator {

  var session: NetworkSession

  public init(session: NetworkSession) {
    self.session = session
  }

  private func makeUrl(action: Action, parameters: [String: String] = [:]) -> String {
    switch action {
    case .LoadUserInformation: return "\(connectPortalUrlBase)\(connectPortalUrls[action]!)"
    case .Logout:
      if !parameters.isEmpty {
        var urlSuffix = ""
        var count = 0
        parameters.keys.forEach { key in
          urlSuffix += "\(key)=\(parameters[key]!)"
          if count < parameters.keys.count - 1 { urlSuffix += "&" }
          count += 1
        }
        return "\(connectPortalUrlBase)\(connectPortalUrls[action]!)?\(urlSuffix)"
      }
      return "\(connectPortalUrlBase)\(connectPortalUrls[action]!)"
    case .CheckConnection: return "\(connectPortalUrlBase)\(connectPortalUrls[action]!)"
    default: return ""
    }
  }

  public var dataSession: DataSession = DataSession(
    username: "", csrfHw: "", wlanUserIp: "", attributeUUID: "")

  public var remainingTime: Result<String, Error> {
    get async {
      let parameters = [
        "op": "getLeftTime",
        "ATTRIBUTE_UUID": dataSession.attributeUUID,
        "CSRFHW": dataSession.csrfHw,
        "wlanuserip": dataSession.wlanUserIp,
        "username": dataSession.username,
      ]

      switch await session.post(
        url: URL(string: makeUrl(action: Action.LoadUserInformation))!, parameters: parameters)
      {
      case .failure(let error): return Result.failure(error)
      case .success(let data): return Result.success(String(data: data, encoding: .utf8) ?? "")
      }
    }
  }

  public func checkConnection() async -> Result<String, Error> {
    switch await session.get(url: URL(string: makeUrl(action: Action.CheckConnection))!) {
    case .failure(let error): return Result.failure(error)
    case .success(let data): return Result.success(String(data: data, encoding: .utf8) ?? "")
    }
  }

  public func getLoginPage() async -> Result<String, Error> {
    switch await session.get(url: URL(string: "https://secure.etecsa.net:8443/")!) {
    case .failure(let error): return Result.failure(error)
    case .success(let data): return Result.success(String(data: data, encoding: .utf8) ?? "")
    }
  }

  public func proxyPost(url: String, parameters: [String: String]) async -> Result<String, Error> {
    switch await session.post(url: URL(string: url)!, parameters: parameters) {
    case .failure(let error): return Result.failure(error)
    case .success(let data): return Result.success(String(data: data, encoding: .utf8) ?? "")
    }
  }

  public func getNautaConnectInformation(parameters: [String: String]) async -> Result<
    String, Error
  > {
    switch await session.post(
      url: URL(string: makeUrl(action: Action.LoadUserInformation))!, parameters: parameters)
    {
    case .failure(let error): return Result.failure(error)
    case .success(let data): return Result.success(String(data: data, encoding: .utf8) ?? "")
    }
  }

  public func disconnect() async -> Result<String, Error> {
    let parameters = [
      "username": dataSession.username,
      "wlanuserip": dataSession.wlanUserIp,
      "CSRFHW": dataSession.csrfHw,
      "ATTRIBUTE_UUID": dataSession.attributeUUID,
    ]

    switch await session.get(
      url: URL(string: makeUrl(action: Action.Logout, parameters: parameters))!)
    {
    case .failure(let error): return Result.failure(error)
    case .success(let data): return Result.success(String(data: data, encoding: .utf8) ?? "")
    }
  }
}
