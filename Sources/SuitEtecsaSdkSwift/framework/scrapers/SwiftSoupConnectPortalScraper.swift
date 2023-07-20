import Foundation
import SwiftSoup

public class SWiftSoupConnectPortalScraper: ConnectPortalScraper {

  public init() {}

  private func getInputs(formElement: Element) -> [String: String] {
    var inputs: [String: String] = [:]
    do {
      try formElement.select("input[name]").forEach { element in
        inputs[try element.attr("name")] = try element.attr("value")
      }
    } catch Exception.Error(_, let message) {
      print(message)
    } catch {
      // Manejar el error
      print("Error: \(error.localizedDescription)")
    }

    return inputs
  }

  public func parseErrors(html: String) -> Result<String, Error> {
    if let doc = try? SwiftSoup.parse(html) {
      do {
        try doc.throwExceptionOnFailure(msg: "nothing", portal: Portal.ConnectPortal)
        return Result.success(html)
      } catch NautaException.genery(let message) {
        return Result.failure(NautaException.genery(message: message))
      } catch {
        return Result.failure(NautaException.genery(message: error.localizedDescription))
      }
    } else {
      return Result.failure(NautaException.genery(message: "Fail to html parse"))
    }
  }

  public func parseCheckConnections(html: String) -> Bool {
    return html.contains(connectDomain)
  }

  public func parseActionForm(html: String) -> Result<(url: String, form: [String: String]), Error>
  {
    if let doc = try? SwiftSoup.parse(html).select("form[action]").first() {
      do {
        let form = getInputs(formElement: doc)
        let url = try doc.attr("action")
        return Result.success((url: url, form: form))
      } catch NautaException.genery(let message) {
        return Result.failure(NautaException.genery(message: message))
      } catch {
        return Result.failure(NautaException.genery(message: error.localizedDescription))
      }
    }
    return Result.success(("", [:]))
  }

  public func parseLoginForm(html: String) -> Result<(url: String, form: [String: String]), Error> {
    if let doc = try? SwiftSoup.parse(html).select("form.form").first() {
      do {
        let form = getInputs(formElement: doc)
        let url = try doc.attr("action")
        return Result.success((url: url, form: form))
      } catch NautaException.genery(let message) {
        return Result.failure(NautaException.genery(message: message))
      } catch {
        return Result.failure(NautaException.genery(message: error.localizedDescription))
      }
    }
    return Result.success(("", [:]))
  }

  public func parseNautaConnectInformation(html: String) -> Result<NautaConnectInformation, Error> {
    let keys = [
      "account_status", "credit", "expiration_date", "access_areas", "from", "to", "time",
    ]

    if let doc = try? SwiftSoup.parse(html) {
      do {
        var info: [String: String] = [:]
        var lastsConnections: [LastsConnection] = []
        var count = 0
        try doc.select("#sessioninfo > tbody > tr > :not(td.key)").forEach { element in
          info[keys[count]] = try element.text().trimmingCharacters(in: .whitespacesAndNewlines)
          count += 1
        }

        let accountInfo = AccountInfo(
          accessAreas: info["access_areas"]!, accountStatus: info["account_status"]!,
          credit: info["credit"]!, expirationDate: info["expiration_date"]!)

        try doc.select("#sesiontraza > tbody > tr").forEach { tr in
          var connection: [String: String] = [:]
          var index = 0
          try tr.select("td").forEach { td in
            connection[keys[index + 4]] = try td.text().trimmingCharacters(
              in: .whitespacesAndNewlines)
            index += 1
          }

          lastsConnections.append(
            LastsConnection(
              from: connection["from"]!, to: connection["time"]!, time: connection["to"]!))
        }
        return Result.success(
          NautaConnectInformation(lastsConnections: lastsConnections, accountInfo: accountInfo))
      } catch NautaException.genery(let message) {
        return Result.failure(NautaException.genery(message: message))
      } catch {
        return Result.failure(NautaException.genery(message: error.localizedDescription))
      }
    }

    return Result.failure(NautaException.loginException(message: "String"))
  }

  public func parseRemainingTime(html: String) -> Result<String, Error> {
    return Result.success(html)
  }

  public func parseAttributeUUID(html: String) -> Result<String, Error> {
    let pattern = "ATTRIBUTE_UUID=(\\w+)&"
    let regex = try? NSRegularExpression(pattern: pattern)
    if let match = regex?.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
      let uuidRange = Range(match.range(at: 1), in: html)
    {
      let uuid = String(html[uuidRange])
      return Result.success(uuid)
    } else {
      return Result.failure(NautaException.getInformationException(message: "String"))
    }
  }

  public func isSuccessLogout(html: String) -> Bool {
    return html.contains("SUCCESS")
  }
}
