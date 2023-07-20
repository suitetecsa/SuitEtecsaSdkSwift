import Foundation
import SwiftSoup

public class SwiftSoupUserPortalScraper: UserPortalScraper {

  public init() {}

  public func parseErrors(html: String) -> Result<String, Error> {
    if let doc = try? SwiftSoup.parse(html) {
      do {
        try doc.throwExceptionOnFailure(msg: "nothing", portal: Portal.UserPortal)
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

  public func parseCsrfToken(html: String) -> Result<String, Error> {
    do {
      let doc = try SwiftSoup.parse(html)
      return Result.success(try doc.select("input[name=csrf]").first()!.attr("value"))
    } catch Exception.Error(_, let message) {
      print(message)
      return Result.failure(NSError(domain: message, code: 0))
    } catch {
      // Manejar el error
      print("Error: \(error.localizedDescription)")
      return Result.failure(NSError(domain: "message", code: 0))
    }
  }

  private func getUserAttr(elementHtml: Element) -> String {
    if let attr = try? elementHtml.select("p").first()!.text().trimmingCharacters(
      in: .whitespacesAndNewlines)
    {
      return attr
    } else {
      return ""
    }
  }

  public func parseNautaUser(html: String) -> Result<NautaUser, Error> {
    do {
      let doc = try SwiftSoup.parse(html)

      let attrs = try doc.select(".z-depth-1").first()!.select(".m6")

      return Result.success(
        NautaUser(
          userName: getUserAttr(elementHtml: attrs[0]),
          blockingDate: getUserAttr(elementHtml: attrs[1]),
          dateOfElimination: getUserAttr(elementHtml: attrs[2]),
          accountType: getUserAttr(elementHtml: attrs[3]),
          serviceType: getUserAttr(elementHtml: attrs[4]),
          credit: getUserAttr(elementHtml: attrs[5]),
          time: getUserAttr(elementHtml: attrs[6]),
          mailAccount: getUserAttr(elementHtml: attrs[7]),
          offer: attrs.size() > 8 ? getUserAttr(elementHtml: attrs[8]) : nil,
          monthlyFee: attrs.size() > 8 ? getUserAttr(elementHtml: attrs[9]) : nil,
          downloadSpeed: attrs.size() > 8 ? getUserAttr(elementHtml: attrs[10]) : nil,
          uploadSpeed: attrs.size() > 8 ? getUserAttr(elementHtml: attrs[11]) : nil,
          phone: attrs.size() > 8 ? getUserAttr(elementHtml: attrs[12]) : nil,
          linkIdentifiers: attrs.size() > 8 ? getUserAttr(elementHtml: attrs[13]) : nil,
          linkStatus: attrs.size() > 8 ? getUserAttr(elementHtml: attrs[14]) : nil,
          activationDate: attrs.size() > 8 ? getUserAttr(elementHtml: attrs[15]) : nil,
          blockingDateHome: attrs.size() > 8 ? getUserAttr(elementHtml: attrs[16]) : nil,
          dateOfEliminationHome: attrs.size() > 8 ? getUserAttr(elementHtml: attrs[17]) : nil,
          quotePaid: attrs.size() > 8 ? getUserAttr(elementHtml: attrs[18]) : nil,
          voucher: attrs.size() > 8 ? getUserAttr(elementHtml: attrs[19]) : nil,
          debt: attrs.size() > 8 ? getUserAttr(elementHtml: attrs[20]) : nil
        )
      )
    } catch Exception.Error(_, let message) {
      print(message)
      return Result.failure(NSError(domain: message, code: 0))
    } catch {
      // Manejar el error
      print("Error: \(error.localizedDescription)")
      return Result.failure(
        NautaException.getInformationException(message: error.localizedDescription))
    }
  }

  public func parseConnectionsSummary(html: String) -> Result<ConnectionsSummary, Error> {
    do {
      let doc = try SwiftSoup.parse(html)
      let attrs = try doc.select("#content").first()!.select(".card-content")

      return Result.success(
        ConnectionsSummary(
          count: Int(try attrs[0].select("input[name=count]").first()!.attr("value"))!,
          yearMonthSelected: try attrs[0].select("input[name=year_month_selected]").first()!.attr(
            "value"),
          totalTime: try attrs[1].select(".card-stats-number").first()!.text().trimmingCharacters(
            in: .whitespacesAndNewlines),
          totalImport: try attrs[2].select(".card-stats-number").first()!.text().trimmingCharacters(
            in: .whitespacesAndNewlines),
          uploaded: try attrs[3].select(".card-stats-number").first()!.text().trimmingCharacters(
            in: .whitespacesAndNewlines),
          downloaded: try attrs[4].select(".card-stats-number").first()!.text().trimmingCharacters(
            in: .whitespacesAndNewlines),
          totalTraffic: try attrs[5].select(".card-stats-number").first()!.text()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        )
      )
    } catch Exception.Error(_, let message) {
      print(message)
      return Result.failure(NSError(domain: message, code: 0))
    } catch {
      // Manejar el error
      print("Error: \(error.localizedDescription)")
      return Result.failure(
        NautaException.getInformationException(message: error.localizedDescription))
    }
  }

  public func parseRechargesSummary(html: String) -> Result<RechargesSummary, Error> {
    do {
      let doc = try SwiftSoup.parse(html)
      let attrs = try doc.select("#content").first()!.select(".card-content")

      return Result.success(
        RechargesSummary(
          count: Int(try attrs[0].select("input[name=count]").first()!.attr("value"))!,
          yearMonthSelected: try attrs[0].select("input[name=year_month_selected]").first()!.attr(
            "value"),
          totalImport: try attrs[2].select(".card-stats-number").first()!.text().trimmingCharacters(
            in: .whitespacesAndNewlines)
        )
      )
    } catch Exception.Error(_, let message) {
      print(message)
      return Result.failure(NSError(domain: message, code: 0))
    } catch {
      // Manejar el error
      print("Error: \(error.localizedDescription)")
      return Result.failure(
        NautaException.getInformationException(message: error.localizedDescription))
    }
  }

  public func parseTransfersSummary(html: String) -> Result<TransfersSummary, Error> {
    do {
      let doc = try SwiftSoup.parse(html)
      let attrs = try doc.select("#content").first()!.select(".card-content")

      return Result.success(
        TransfersSummary(
          count: Int(try attrs[0].select("input[name=count]").first()!.attr("value"))!,
          yearMonthSelected: try attrs[0].select("input[name=year_month_selected]").first()!.attr(
            "value"),
          totalImport: try attrs[1].select(".card-stats-number").first()!.text().trimmingCharacters(
            in: .whitespacesAndNewlines)
        )
      )
    } catch Exception.Error(_, let message) {
      print(message)
      return Result.failure(NSError(domain: message, code: 0))
    } catch {
      // Manejar el error
      print("Error: \(error.localizedDescription)")
      return Result.failure(
        NautaException.getInformationException(message: error.localizedDescription))
    }
  }

  public func parseQuotesPaidSummary(html: String) -> Result<QuotesPaidSummary, Error> {
    do {
      let doc = try SwiftSoup.parse(html)
      let attrs = try doc.select("#content").first()!.select(".card-content")

      return Result.success(
        QuotesPaidSummary(
          count: Int(try attrs[0].select("input[name=count]").first()!.attr("value"))!,
          yearMonthSelected: try attrs[0].select("input[name=year_month_selected]").first()!.attr(
            "value"),
          totalImport: try attrs[2].select(".card-stats-number").first()!.text().trimmingCharacters(
            in: .whitespacesAndNewlines)
        )
      )
    } catch Exception.Error(_, let message) {
      print(message)
      return Result.failure(NSError(domain: message, code: 0))
    } catch {
      // Manejar el error
      print("Error: \(error.localizedDescription)")
      return Result.failure(
        NautaException.getInformationException(message: error.localizedDescription))
    }
  }

  public func parseConnections(html: String) -> Result<[Connection], Error> {
    var connections = [Connection]()

    do {
      let doc = try SwiftSoup.parse(html)
      let tableBody = try doc.select(".responsive-table > tbody").first()!
      if let rows = try? tableBody.select("tr") {
        try rows.forEach { row in
          let attr = try row.select("td")
          connections.append(
            Connection(
              startSession: try attr[0].text().trimmingCharacters(in: .whitespacesAndNewlines),
              endSession: try attr[1].text().trimmingCharacters(in: .whitespacesAndNewlines),
              duration: try attr[2].text().trimmingCharacters(in: .whitespacesAndNewlines),
              uploaded: try attr[3].text().trimmingCharacters(in: .whitespacesAndNewlines),
              downloaded: try attr[4].text().trimmingCharacters(in: .whitespacesAndNewlines),
              import_: try attr[5].text().trimmingCharacters(in: .whitespacesAndNewlines)
            )
          )
        }
      }
    } catch Exception.Error(_, let message) {
      print(message)
      return Result.failure(NSError(domain: message, code: 0))
    } catch {
      // Manejar el error
      print("Error: \(error.localizedDescription)")
      return Result.failure(
        NautaException.getInformationException(message: error.localizedDescription))
    }
    return Result.success(connections)
  }

  public func parseRecharges(html: String) -> Result<[Recharge], Error> {
    var recharges = [Recharge]()

    do {
      let doc = try SwiftSoup.parse(html)
      let tableBody = try doc.select(".responsive-table > tbody").first()!
      if let rows = try? tableBody.select("tr") {
        try rows.forEach { row in
          let attr = try row.select("td")
          recharges.append(
            Recharge(
              date: try attr[0].text().trimmingCharacters(in: .whitespacesAndNewlines),
              import_: try attr[1].text().trimmingCharacters(in: .whitespacesAndNewlines),
              channel: try attr[2].text().trimmingCharacters(in: .whitespacesAndNewlines),
              type: try attr[3].text().trimmingCharacters(in: .whitespacesAndNewlines)
            )
          )
        }
      }
    } catch Exception.Error(_, let message) {
      print(message)
      return Result.failure(NSError(domain: message, code: 0))
    } catch {
      // Manejar el error
      print("Error: \(error.localizedDescription)")
      return Result.failure(
        NautaException.getInformationException(message: error.localizedDescription))
    }
    return Result.success(recharges)
  }

  public func parseTransfers(html: String) -> Result<[Transfer], Error> {
    var tansfers = [Transfer]()

    do {
      let doc = try SwiftSoup.parse(html)
      let tableBody = try doc.select(".responsive-table > tbody").first()!
      if let rows = try? tableBody.select("tr") {
        try rows.forEach { row in
          let attr = try row.select("td")
          tansfers.append(
            Transfer(
              date: try attr[0].text().trimmingCharacters(in: .whitespacesAndNewlines),
              import_: try attr[1].text().trimmingCharacters(in: .whitespacesAndNewlines),
              destinyAccount: try attr[2].text().trimmingCharacters(in: .whitespacesAndNewlines)
            )
          )
        }
      }
    } catch Exception.Error(_, let message) {
      print(message)
      return Result.failure(NSError(domain: message, code: 0))
    } catch {
      // Manejar el error
      print("Error: \(error.localizedDescription)")
      return Result.failure(
        NautaException.getInformationException(message: error.localizedDescription))
    }
    return Result.success(tansfers)
  }

  public func parseQuotesPaid(html: String) -> Result<[QuotePaid], Error> {
    var quotesPaid = [QuotePaid]()

    do {
      let doc = try SwiftSoup.parse(html)
      let tableBody = try doc.select(".responsive-table > tbody").first()!
      if let rows = try? tableBody.select("tr") {
        try rows.forEach { row in
          let attr = try row.select("td")
          quotesPaid.append(
            QuotePaid(
              date: try attr[0].text().trimmingCharacters(in: .whitespacesAndNewlines),
              import_: try attr[1].text().trimmingCharacters(in: .whitespacesAndNewlines),
              channel: try attr[2].text().trimmingCharacters(in: .whitespacesAndNewlines),
              type: try attr[3].text().trimmingCharacters(in: .whitespacesAndNewlines),
              office: try attr[4].text().trimmingCharacters(in: .whitespacesAndNewlines)
            )
          )
        }
      }
    } catch Exception.Error(_, let message) {
      print(message)
      return Result.failure(NSError(domain: message, code: 0))
    } catch {
      // Manejar el error
      print("Error: \(error.localizedDescription)")
      return Result.failure(
        NautaException.getInformationException(message: error.localizedDescription))
    }
    return Result.success(quotesPaid)
  }
}
