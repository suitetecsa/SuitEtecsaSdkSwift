import Foundation

public class NautaApi {
  var userPortalCommunicator: UserPortalCommunicator
  var userPortalScraper: UserPortalScraper
  var connectPortalCommunicator: ConnectPortalCommunicator
  var connectPortalScraper: ConnectPortalScraper

  public init(
    userPortalCommunicator: UserPortalCommunicator,
    userPortalScraper: UserPortalScraper,
    connectPortalCommunicator: ConnectPortalCommunicator,
    connectPortalScraper: ConnectPortalScraper
  ) {
    self.userPortalCommunicator = userPortalCommunicator
    self.userPortalScraper = userPortalScraper
    self.connectPortalCommunicator = connectPortalCommunicator
    self.connectPortalScraper = connectPortalScraper
  }

  var actionLogin = ""

  public var credentials: (username: String, password: String) = ("", "")

  public var isUnderNautaCaptivePortal: Bool {
    get async throws {
      switch await connectPortalCommunicator.checkConnection() {
      case .failure(let error): throw error
      case .success(let html):
        return connectPortalScraper.parseCheckConnections(html: html)
      }
    }
  }

  private var _isNautaHome: Bool = false
  public var isNautaHome: Bool {
    return _isNautaHome
  }

  public func initConnectPortalSession() async throws {
    switch await connectPortalCommunicator.getLoginPage() {
    case .failure(let error): throw error
    case .success(let loginHtml):
      switch connectPortalScraper.parseLoginForm(html: loginHtml) {
      case .failure(let error): throw error
      case .success(let loginResult):
        actionLogin = loginResult.url
        connectPortalCommunicator.dataSession.wlanUserIp = loginResult.form["wlanuserip"]!
        connectPortalCommunicator.dataSession.csrfHw = loginResult.form["CSRFHW"]!
      }
    }
  }

  public func initUserPortalSession() async throws {
    switch await userPortalCommunicator.loadCsrf(action: Action.Login) {
    case .success(let csrfHtml):
      switch userPortalScraper.parseCsrfToken(html: csrfHtml) {
      case .failure(let error): throw error
      case .success(let csrf): userPortalCommunicator.csrf = csrf
      }
    case .failure(let error): throw error
    }
  }

  public var captchaImage: Data {
    get async throws {
      let captcha = await userPortalCommunicator.getCaptcha()
      switch captcha {
      case .success(let data): return data
      case .failure(let error): throw error
      }
    }
  }

  public func connect() async throws {
    try await initConnectPortalSession()
    let parameters = [
      "CSRFHW": connectPortalCommunicator.dataSession.csrfHw,
      "wlanuserip": connectPortalCommunicator.dataSession.wlanUserIp,
      "username": credentials.username,
      "password": credentials.password,
    ]
    switch await connectPortalCommunicator.proxyPost(url: actionLogin, parameters: parameters) {
    case .failure(let error): throw error
    case .success(let html):
      switch connectPortalScraper.parseAttributeUUID(html: html) {
      case .failure(let error): throw error
      case .success(let attributeUuid):
        connectPortalCommunicator.dataSession.attributeUUID = attributeUuid
        connectPortalCommunicator.dataSession.username = credentials.username
      }
    }
  }

  public func login(captchaCode: String) async throws -> NautaUser {
    switch await userPortalCommunicator.login(
      username: credentials.username, password: credentials.password, captchaCode: captchaCode)
    {
    case .success(let html):
      switch userPortalScraper.parseErrors(html: html) {
      case .failure(let error): throw error
      case .success(let htmlOk):
        switch userPortalScraper.parseNautaUser(html: htmlOk) {
        case .success(let user):
          _isNautaHome = user.offer != nil
          return user
        case .failure(let error): throw error
        }
      }
    case .failure(let error): throw error
    }
  }

  public var userInformation: NautaUser {
    get async throws {
      switch await userPortalCommunicator.loadCsrf(action: Action.LoadUserInformation) {
      case .success(let csrfHtml):
        switch userPortalScraper.parseCsrfToken(html: csrfHtml) {
        case .failure(let error): throw error
        case .success(let csrf): userPortalCommunicator.csrf = csrf
        }
      case .failure(let error): throw error
      }

      switch await userPortalCommunicator.userInformation {
      case .failure(let error): throw error
      case .success(let html):
        switch userPortalScraper.parseNautaUser(html: html) {
        case .failure(let error): throw error
        case .success(let user): return user
        }
      }
    }
  }

  public var remainingTime: String {
    get async throws {
      switch await connectPortalCommunicator.remainingTime {
      case .failure(let error): throw error
      case .success(let html): return html
      }
    }
  }

  public var connectInformation: NautaConnectInformation {
    get async throws {
      try await initConnectPortalSession()
      let parameters = [
        "username": credentials.username,
        "password": credentials.password,
        "wlanuserip": connectPortalCommunicator.dataSession.wlanUserIp,
        "CSRFHW": connectPortalCommunicator.dataSession.csrfHw,
        "lang": "",
      ]
      let url = "https://\(connectDomain):8443/EtecsaQueryServlet"
      switch await connectPortalCommunicator.proxyPost(url: url, parameters: parameters) {
      case .failure(let error): throw error
      case .success(let html):
        switch connectPortalScraper.parseNautaConnectInformation(html: html) {
        case .failure(let error): throw error
        case .success(let userInformation): return userInformation
        }
      }
    }
  }

  public func disconnect() async throws {
    switch await connectPortalCommunicator.disconnect() {
    case .failure(let error): throw error
    case .success(let html):
      if connectPortalScraper.isSuccessLogout(html: html) {
        break
      } else {
        throw NautaException.genery(message: "No se pudo cerrar sesion")
      }
    }
  }

  public func topUp(rechargeCode: String) async throws {
    switch await userPortalCommunicator.loadCsrf(action: Action.Recharge) {
    case .success(let csrfHtml):
      switch userPortalScraper.parseCsrfToken(html: csrfHtml) {
      case .failure(let error): throw error
      case .success(let csrf): userPortalCommunicator.csrf = csrf
      }
    case .failure(let error): throw error
    }

    switch await userPortalCommunicator.topUp(rechargeCode: rechargeCode) {
    case .failure(let error): throw error
    case .success(let html):
      switch userPortalScraper.parseErrors(html: html) {
      case .failure(let error): throw error
      case .success(_): break
      }
    }
  }

  public func transfer(amount: Float, destinationAccount: String) async throws {
    switch await userPortalCommunicator.loadCsrf(action: Action.Transfer) {
    case .success(let csrfHtml):
      switch userPortalScraper.parseCsrfToken(html: csrfHtml) {
      case .failure(let error): throw error
      case .success(let csrf): userPortalCommunicator.csrf = csrf
      }
    case .failure(let error): throw error
    }

    switch await userPortalCommunicator.transfer(
      amount: amount, password: credentials.password, destinationAccount: destinationAccount)
    {
    case .failure(let error): throw error
    case .success(let html):
      switch userPortalScraper.parseErrors(html: html) {
      case .failure(let error): throw error
      case .success(_): break
      }
    }
  }

  public func payNautaHome(amount: Float) async throws {
    switch await userPortalCommunicator.loadCsrf(action: Action.Transfer) {
    case .success(let csrfHtml):
      switch userPortalScraper.parseCsrfToken(html: csrfHtml) {
      case .failure(let error): throw error
      case .success(let csrf): userPortalCommunicator.csrf = csrf
      }
    case .failure(let error): throw error
    }

    switch await userPortalCommunicator.transfer(
      amount: amount, password: credentials.password, destinationAccount: nil)
    {
    case .failure(let error): throw error
    case .success(let html):
      switch userPortalScraper.parseErrors(html: html) {
      case .failure(let error): throw error
      case .success(_): break
      }
    }
  }

  public func changePassword(newPassword: String) async throws {
    switch await userPortalCommunicator.loadCsrf(action: Action.ChangePassword) {
    case .success(let csrfHtml):
      switch userPortalScraper.parseCsrfToken(html: csrfHtml) {
      case .failure(let error): throw error
      case .success(let csrf): userPortalCommunicator.csrf = csrf
      }
    case .failure(let error): throw error
    }

    switch await userPortalCommunicator.changePassword(
      oldPassword: credentials.password, newPassword: newPassword)
    {
    case .failure(let error): throw error
    case .success(let html):
      switch userPortalScraper.parseErrors(html: html) {
      case .failure(let error): throw error
      case .success(_): break
      }
    }
  }

  public func changeEmailPassword(oldPassword: String, newPassword: String) async throws {
    switch await userPortalCommunicator.loadCsrf(action: Action.ChangeEmailPassword) {
    case .success(let csrfHtml):
      switch userPortalScraper.parseCsrfToken(html: csrfHtml) {
      case .failure(let error): throw error
      case .success(let csrf): userPortalCommunicator.csrf = csrf
      }
    case .failure(let error): throw error
    }

    switch await userPortalCommunicator.changeEmailPassword(
      oldPassword: oldPassword, newPassword: newPassword)
    {
    case .failure(let error): throw error
    case .success(let html):
      switch userPortalScraper.parseErrors(html: html) {
      case .failure(let error): throw error
      case .success(_): break
      }
    }
  }

  public func getConnectionsSummary(year: Int, month: Int) async throws -> ConnectionsSummary {
    switch await userPortalCommunicator.loadCsrf(action: Action.GetConnections) {
    case .success(let csrfHtml):
      switch userPortalScraper.parseCsrfToken(html: csrfHtml) {
      case .failure(let error): throw error
      case .success(let csrf): userPortalCommunicator.csrf = csrf
      }
    case .failure(let error): throw error
    }

    switch await userPortalCommunicator.getConnectionsSummary(year: year, month: month) {
    case .failure(let error): throw error
    case .success(let html):
      switch userPortalScraper.parseConnectionsSummary(html: html) {
      case .failure(let error): throw error
      case .success(let summary): return summary
      }
    }
  }

  public func getRechargesSummary(year: Int, month: Int) async throws -> RechargesSummary {
    switch await userPortalCommunicator.loadCsrf(action: Action.GetRecharges) {
    case .success(let csrfHtml):
      switch userPortalScraper.parseCsrfToken(html: csrfHtml) {
      case .failure(let error): throw error
      case .success(let csrf): userPortalCommunicator.csrf = csrf
      }
    case .failure(let error): throw error
    }

    switch await userPortalCommunicator.getRechargesSummary(year: year, month: month) {
    case .failure(let error): throw error
    case .success(let html):
      switch userPortalScraper.parseRechargesSummary(html: html) {
      case .failure(let error): throw error
      case .success(let summary): return summary
      }
    }
  }

  public func getTransfersSummary(year: Int, month: Int) async throws -> TransfersSummary {
    switch await userPortalCommunicator.loadCsrf(action: Action.GetTransfers) {
    case .success(let csrfHtml):
      switch userPortalScraper.parseCsrfToken(html: csrfHtml) {
      case .failure(let error): throw error
      case .success(let csrf): userPortalCommunicator.csrf = csrf
      }
    case .failure(let error): throw error
    }

    switch await userPortalCommunicator.getTransfersSummary(year: year, month: month) {
    case .failure(let error): throw error
    case .success(let html):
      switch userPortalScraper.parseTransfersSummary(html: html) {
      case .failure(let error): throw error
      case .success(let summary): return summary
      }
    }
  }

  public func getQuotesPaidSummary(year: Int, month: Int) async throws -> QuotesPaidSummary {
    switch await userPortalCommunicator.loadCsrf(action: Action.GetQuotesPaid) {
    case .success(let csrfHtml):
      switch userPortalScraper.parseCsrfToken(html: csrfHtml) {
      case .failure(let error): throw error
      case .success(let csrf): userPortalCommunicator.csrf = csrf
      }
    case .failure(let error): throw error
    }

    switch await userPortalCommunicator.getQuotesPaidSummary(year: year, month: month) {
    case .failure(let error): throw error
    case .success(let html):
      switch userPortalScraper.parseQuotesPaidSummary(html: html) {
      case .failure(let error): throw error
      case .success(let summary): return summary
      }
    }
  }

  public func getConnections(
    connectionsSummary: ConnectionsSummary, large: Int = 0, reversed: Bool = false
  ) async throws -> [Connection] {
    var connections = [Connection]()

    switch await userPortalCommunicator.getConnections(
      connectionsSummary: connectionsSummary, large: large, reversed: reversed)
    {
    case .failure(let error): throw error
    case .success(let actionsRaw):
      try actionsRaw.forEach { html in
        switch userPortalScraper.parseConnections(html: html) {
        case .failure(let error): throw error
        case .success(let actions):
          let elements = reversed ? actions.reversed() : actions
          elements.forEach { element in connections.append(element) }
        }
      }
    }

    return connections
  }

  public func getRecharges(
    rechargessSummary: RechargesSummary, large: Int = 0, reversed: Bool = false
  ) async throws -> [Recharge] {
    var recharges = [Recharge]()

    switch await userPortalCommunicator.getRecharges(
      rechargesSummary: rechargessSummary, large: large, reversed: reversed)
    {
    case .failure(let error): throw error
    case .success(let actionsRaw):
      try actionsRaw.forEach { html in
        switch userPortalScraper.parseRecharges(html: html) {
        case .failure(let error): throw error
        case .success(let actions):
          let elements = reversed ? actions.reversed() : actions
          elements.forEach { element in recharges.append(element) }
        }
      }
    }

    return recharges
  }

  public func getTransfers(
    transfersSummary: TransfersSummary, large: Int = 0, reversed: Bool = false
  ) async throws -> [Transfer] {
    var transfers = [Transfer]()

    switch await userPortalCommunicator.getTransfers(
      transfersSummary: transfersSummary, large: large, reversed: reversed)
    {
    case .failure(let error): throw error
    case .success(let actionsRaw):
      try actionsRaw.forEach { html in
        switch userPortalScraper.parseTransfers(html: html) {
        case .failure(let error): throw error
        case .success(let actions):
          let elements = reversed ? actions.reversed() : actions
          elements.forEach { element in transfers.append(element) }
        }
      }
    }

    return transfers
  }

  public func getQuotesPaid(
    quotesPaidSummary: QuotesPaidSummary, large: Int = 0, reversed: Bool = false
  ) async throws -> [QuotePaid] {
    var quotesPaid = [QuotePaid]()

    switch await userPortalCommunicator.getQuotesPaid(
      quotesPaidSummary: quotesPaidSummary, large: large, reversed: reversed)
    {
    case .failure(let error): throw error
    case .success(let actionsRaw):
      try actionsRaw.forEach { html in
        switch userPortalScraper.parseQuotesPaid(html: html) {
        case .failure(let error): throw error
        case .success(let actions):
          let elements = reversed ? actions.reversed() : actions
          elements.forEach { element in quotesPaid.append(element) }
        }
      }
    }

    return quotesPaid
  }
}
