import Foundation

public class DefaultUserPortalCommunicator: UserPortalCommunicator {

  public var csrf: String = ""

  var session: NetworkSession
  public init(session: NetworkSession) {
    self.session = session
  }

  private func makeUrl(
    action: Action,
    getAction: Bool = false,
    subAction: String? = nil,
    yearMonthSelected: String? = nil,
    count: Int? = nil,
    page: Int? = nil
  ) -> Result<String, Error> {
    if !getAction {
      return Result.success("\(userPortalUrlBase)\(userPortalUrls[action]!)")
    } else {
      let url =
        "\(userPortalUrlBase)\((userPortalUrls[action]! as! [String : String])[subAction!]!)"
      switch subAction! {
      case "base":
        return Result.success(url)
      case "summary":
        return Result.success(url)
      case "list":
        if let yearMonthSelected = (yearMonthSelected) {
          if yearMonthSelected.isEmpty {
            return Result.failure(NSError(domain: "yearMonthSelected is required", code: 5))
          }
        } else {
          return Result.failure(NSError(domain: "yearMonthSelected is required", code: 5))
        }

        if count == nil { return Result.failure(NSError(domain: "count is required", code: 6)) }

        return Result.success(
          page != nil
            ? "\(url)\(yearMonthSelected!)/\(count!)/\(page!)"
            : "\(url)\(yearMonthSelected!)/\(count!)")

      default: return Result.failure(NSError(domain: "", code: 4))
      }
    }
  }

  public func loadCsrf(action: Action) async -> Result<String, Error> {
    let url: Result<String, Error>
    switch action {
    case Action.GetConnections:
      url = makeUrl(action: action, getAction: true, subAction: "base")
    case Action.GetRecharges:
      url = makeUrl(action: action, getAction: true, subAction: "base")
    case Action.GetTransfers:
      url = makeUrl(action: action, getAction: true, subAction: "base")
    case Action.GetQuotesPaid:
      url = makeUrl(action: action, getAction: true, subAction: "base")
    default:
      url = makeUrl(action: action)
    }

    switch url {
    case .success(let url):
      let response = await session.get(url: URL(string: url)!)

      switch response {
      case .success(let data):
        return Result.success(String(data: data, encoding: .utf8) ?? "")
      case .failure(let error):
        return Result.failure(
          NautaException.getInformationException(
            message: "Fail to obtain csrf token :: \(error.localizedDescription)"))
      }
    case .failure(let error):
      return Result.failure(
        NautaException.getInformationException(
          message: "Fail to obtain csrf token :: \(error.localizedDescription)"))
    }

  }

  public func getCaptcha() async -> Result<Data, Error> {
    return await session.get(url: URL(string: "https://www.portal.nauta.cu/captcha/?")!)

  }

  public func login(username: String, password: String, captchaCode: String) async -> Result<
    String, Error
  > {
    let action = Action.Login
    let url = makeUrl(action: action)

    switch url {
    case .success(let url):
      let response = await session.post(
        url: URL(string: url)!,
        parameters: [
          "csrf": self.csrf,
          "login_user": username,
          "password_user": password,
          "captcha": captchaCode,
          "btn_submit": "",
        ])

      switch response {
      case .success(let data):
        return Result.success(String(data: data, encoding: .utf8) ?? "")
      case .failure(let error):
        return Result.failure(
          NautaException.loginException(message: "Fail to login :: \(error.localizedDescription)"))
      }
    case .failure(let error):
      return Result.failure(
        NautaException.loginException(message: "Fail to login :: \(error.localizedDescription)"))
    }
  }

  public var userInformation: Result<String, Error> {
    get async {
      switch makeUrl(action: Action.LoadUserInformation) {
      case .failure(let error): return Result.failure(error)
      case .success(let url):
        switch await session.get(url: URL(string: url)!) {
        case .failure(let error): return Result.failure(error)
        case .success(let data): return Result.success(String(data: data, encoding: .utf8) ?? "")
        }
      }
    }
  }

  public func topUp(rechargeCode: String) async -> Result<String, Error> {
    let url = makeUrl(action: Action.Recharge)

    switch url {
    case .failure(let error):
      return Result.failure(
        NautaException.topUpException(message: "Fail to top up :: \(error.localizedDescription)"))
    case .success(let url):
      let response = await session.post(
        url: URL(string: url)!,
        parameters: ["csrf": self.csrf, "recharge_code": rechargeCode, "btn_submit": ""])

      switch response {
      case .success(let data):
        return Result.success(String(data: data, encoding: .utf8) ?? "")
      case .failure(let error):
        return Result.failure(
          NautaException.topUpException(message: "Failt to top up :: \(error.localizedDescription)")
        )
      }
    }
  }

  public func transfer(amount: Float, password: String, destinationAccount: String? = nil) async
    -> Result<String, Error>
  {
    var parameters = [
      "csrf": self.csrf,
      "transfer": String(format: "%.2f", arguments: [amount]).replacingOccurrences(
        of: ".", with: ","),
      "password_user": password,
      "action": "checkdata",
    ]

    if let destinationAccount {
      parameters["id_cuenta"] = destinationAccount
    }

    switch makeUrl(action: Action.Transfer) {
    case .failure(let error):
      return Result.failure(NautaException.transferException(message: error.localizedDescription))
    case .success(let url):
      switch await session.post(url: URL(string: url)!, parameters: parameters) {
      case .failure(let error):
        return Result.failure(NautaException.transferException(message: error.localizedDescription))
      case .success(let data): return Result.success(String(data: data, encoding: .utf8) ?? "")
      }

    }
  }

  public func changePassword(oldPassword: String, newPassword: String) async -> Result<
    String, Error
  > {
    let parameters = [
      "csrf": self.csrf,
      "old_password": oldPassword,
      "new_password": newPassword,
      "repeat_new_password": newPassword,
      "btn_submit": "",
    ]

    switch makeUrl(action: Action.ChangePassword) {
    case .failure(let error):
      return Result.failure(
        NautaException.changePasswordException(message: error.localizedDescription))
    case .success(let url):
      switch await session.post(url: URL(string: url)!, parameters: parameters) {
      case .failure(let error):
        return Result.failure(
          NautaException.changePasswordException(message: error.localizedDescription))
      case .success(let data): return Result.success(String(data: data, encoding: .utf8) ?? "")
      }
    }
  }

  public func changeEmailPassword(oldPassword: String, newPassword: String) async -> Result<
    String, Error
  > {
    let parameters = [
      "csrf": self.csrf,
      "old_password": oldPassword,
      "new_password": newPassword,
      "repeat_new_password": newPassword,
      "btn_submit": "",
    ]

    switch makeUrl(action: Action.ChangeEmailPassword) {
    case .failure(let error):
      return Result.failure(
        NautaException.changePasswordException(message: error.localizedDescription))
    case .success(let url):
      switch await session.post(url: URL(string: url)!, parameters: parameters) {
      case .failure(let error):
        return Result.failure(
          NautaException.changePasswordException(message: error.localizedDescription))
      case .success(let data): return Result.success(String(data: data, encoding: .utf8) ?? "")
      }
    }
  }

  public func getConnectionsSummary(year: Int, month: Int) async -> Result<String, Error> {
    let yearMonthSelected = "\(year)-\(String(format: "%02d", arguments: [month]))"
    let parameters = [
      "csrf": self.csrf,
      "year_month": yearMonthSelected,
      "list_type": "service_detail",
    ]

    switch makeUrl(action: Action.GetConnections, getAction: true, subAction: "summary") {
    case .failure(let error):
      return Result.failure(
        NautaException.getInformationException(message: error.localizedDescription))
    case .success(let url):
      switch await session.post(url: URL(string: url)!, parameters: parameters) {
      case .failure(let error):
        return Result.failure(
          NautaException.getInformationException(message: error.localizedDescription))
      case .success(let data): return Result.success(String(data: data, encoding: .utf8) ?? "")
      }
    }
  }

  public func getRechargesSummary(year: Int, month: Int) async -> Result<String, Error> {
    let yearMonthSelected = "\(year)-\(String(format: "%02d", arguments: [month]))"
    let parameters = [
      "csrf": self.csrf,
      "year_month": yearMonthSelected,
      "list_type": "recharge_detail",
    ]

    switch makeUrl(action: Action.GetRecharges, getAction: true, subAction: "summary") {
    case .failure(let error):
      return Result.failure(
        NautaException.getInformationException(message: error.localizedDescription))
    case .success(let url):
      switch await session.post(url: URL(string: url)!, parameters: parameters) {
      case .failure(let error):
        return Result.failure(
          NautaException.getInformationException(message: error.localizedDescription))
      case .success(let data): return Result.success(String(data: data, encoding: .utf8) ?? "")
      }
    }
  }

  public func getTransfersSummary(year: Int, month: Int) async -> Result<String, Error> {
    let yearMonthSelected = "\(year)-\(String(format: "%02d", arguments: [month]))"
    let parameters = [
      "csrf": self.csrf,
      "year_month": yearMonthSelected,
      "list_type": "transfer_detail",
    ]

    switch makeUrl(action: Action.GetTransfers, getAction: true, subAction: "summary") {
    case .failure(let error):
      return Result.failure(
        NautaException.getInformationException(message: error.localizedDescription))
    case .success(let url):
      switch await session.post(url: URL(string: url)!, parameters: parameters) {
      case .failure(let error):
        return Result.failure(
          NautaException.getInformationException(message: error.localizedDescription))
      case .success(let data): return Result.success(String(data: data, encoding: .utf8) ?? "")
      }
    }
  }

  public func getQuotesPaidSummary(year: Int, month: Int) async -> Result<String, Error> {
    let yearMonthSelected = "\(year)-\(String(format: "%02d", arguments: [month]))"
    let parameters = [
      "csrf": self.csrf,
      "year_month": yearMonthSelected,
      "list_type": "nautahogarpaid_detail",
    ]

    switch makeUrl(action: Action.GetQuotesPaid, getAction: true, subAction: "summary") {
    case .failure(let error):
      return Result.failure(
        NautaException.getInformationException(message: error.localizedDescription))
    case .success(let url):
      switch await session.post(url: URL(string: url)!, parameters: parameters) {
      case .failure(let error):
        return Result.failure(
          NautaException.getInformationException(message: error.localizedDescription))
      case .success(let data): return Result.success(String(data: data, encoding: .utf8) ?? "")
      }
    }
  }

  public func getConnections(
    connectionsSummary: ConnectionsSummary, large: Int = 0, reversed: Bool = false
  ) async -> Result<[String], Error> {
    var connections = [String]()
    let internalLarge =
      large == 0 || large > connectionsSummary.count ? connectionsSummary.count : large

    if connectionsSummary.count != 0 {
      let totalPages = Int(ceil(Double(connectionsSummary.count) / 14.0))
      var currentPage = reversed ? totalPages : 1
      let rest = (reversed || currentPage == totalPages) && totalPages != 1 ? totalPages % 14 : 0
      while ((connections.count * 14) - rest) < internalLarge && currentPage >= 1 {
        let page = currentPage != 1 ? currentPage : nil
        switch makeUrl(
          action: Action.GetConnections, getAction: true, subAction: "list",
          yearMonthSelected: connectionsSummary.yearMonthSelected, count: connectionsSummary.count,
          page: page)
        {
        case .failure(let error):
          return Result.failure(
            NautaException.getInformationException(message: error.localizedDescription))
        case .success(let url):
          switch await session.get(url: URL(string: url)!) {
          case .failure(let error):
            return Result.failure(
              NautaException.getInformationException(message: error.localizedDescription))
          case .success(let data): connections.append(String(data: data, encoding: .utf8) ?? "")
          }
        }
        currentPage += reversed ? -1 : 1
      }
    }
    return Result.success(connections)
  }

  public func getRecharges(rechargesSummary: RechargesSummary, large: Int, reversed: Bool) async
    -> Result<[String], Error>
  {
    var recharges = [String]()
    let internalLarge =
      large == 0 || large > rechargesSummary.count ? rechargesSummary.count : large

    if rechargesSummary.count != 0 {
      let totalPages = Int(ceil(Double(rechargesSummary.count) / 14.0))
      var currentPage = reversed ? totalPages : 1
      let rest = (reversed || currentPage == totalPages) && totalPages != 1 ? totalPages % 14 : 0
      while ((recharges.count * 14) - rest) < internalLarge && currentPage >= 1 {
        let page = currentPage != 1 ? currentPage : nil
        switch makeUrl(
          action: Action.GetRecharges, getAction: true, subAction: "list",
          yearMonthSelected: rechargesSummary.yearMonthSelected, count: rechargesSummary.count,
          page: page)
        {
        case .failure(let error):
          return Result.failure(
            NautaException.getInformationException(message: error.localizedDescription))
        case .success(let url):
          switch await session.get(url: URL(string: url)!) {
          case .failure(let error):
            return Result.failure(
              NautaException.getInformationException(message: error.localizedDescription))
          case .success(let data): recharges.append(String(data: data, encoding: .utf8) ?? "")
          }
        }
        currentPage += reversed ? -1 : 1
      }
    }
    return Result.success(recharges)
  }

  public func getTransfers(transfersSummary: TransfersSummary, large: Int, reversed: Bool) async
    -> Result<[String], Error>
  {
    var transfers = [String]()
    let internalLarge =
      large == 0 || large > transfersSummary.count ? transfersSummary.count : large

    if transfersSummary.count != 0 {
      let totalPages = Int(ceil(Double(transfersSummary.count) / 14.0))
      var currentPage = reversed ? totalPages : 1
      let rest = (reversed || currentPage == totalPages) && totalPages != 1 ? totalPages % 14 : 0
      while ((transfers.count * 14) - rest) < internalLarge && currentPage >= 1 {
        let page = currentPage != 1 ? currentPage : nil
        switch makeUrl(
          action: Action.GetTransfers, getAction: true, subAction: "list",
          yearMonthSelected: transfersSummary.yearMonthSelected, count: transfersSummary.count,
          page: page)
        {
        case .failure(let error):
          return Result.failure(
            NautaException.getInformationException(message: error.localizedDescription))
        case .success(let url):
          switch await session.get(url: URL(string: url)!) {
          case .failure(let error):
            return Result.failure(
              NautaException.getInformationException(message: error.localizedDescription))
          case .success(let data): transfers.append(String(data: data, encoding: .utf8) ?? "")
          }
        }
        currentPage += reversed ? -1 : 1
      }
    }
    return Result.success(transfers)
  }

  public func getQuotesPaid(quotesPaidSummary: QuotesPaidSummary, large: Int, reversed: Bool) async
    -> Result<[String], Error>
  {
    var quotesPaid = [String]()
    let internalLarge =
      large == 0 || large > quotesPaidSummary.count ? quotesPaidSummary.count : large

    if quotesPaidSummary.count != 0 {
      let totalPages = Int(ceil(Double(quotesPaidSummary.count) / 14.0))
      var currentPage = reversed ? totalPages : 1
      let rest = (reversed || currentPage == totalPages) && totalPages != 1 ? totalPages % 14 : 0
      while ((quotesPaid.count * 14) - rest) < internalLarge && currentPage >= 1 {
        let page = currentPage != 1 ? currentPage : nil
        switch makeUrl(
          action: Action.GetQuotesPaid, getAction: true, subAction: "list",
          yearMonthSelected: quotesPaidSummary.yearMonthSelected, count: quotesPaidSummary.count,
          page: page)
        {
        case .failure(let error):
          return Result.failure(
            NautaException.getInformationException(message: error.localizedDescription))
        case .success(let url):
          switch await session.get(url: URL(string: url)!) {
          case .failure(let error):
            return Result.failure(
              NautaException.getInformationException(message: error.localizedDescription))
          case .success(let data): quotesPaid.append(String(data: data, encoding: .utf8) ?? "")
          }
        }
        currentPage += reversed ? -1 : 1
      }
    }
    return Result.success(quotesPaid)
  }

}
