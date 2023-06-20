public protocol ConnectPortalCommunicator {
    var dataSession: DataSession { get set }
    var remainingTime: Result<String, Error> { get async  }

    func checkConnection() async -> Result<String, Error>
    func getLoginPage() async -> Result<String, Error>
    func proxyPost(url: String, parameters: [String: String]) async -> Result<String, Error>
    func getNautaConnectInformation(parameters: [String : String]) async -> Result<String, Error>
    func disconnect() async -> Result<String, Error>
}