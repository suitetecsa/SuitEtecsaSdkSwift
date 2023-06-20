public protocol UserPortalScraper {
    func parseErrors(html: String) -> Result<String, Error>
    func parseCsrfToken(html: String) -> Result<String, Error>
    func parseNautaUser(html: String) -> Result<NautaUser, Error>
    func parseConnectionsSummary(html: String) -> Result<ConnectionsSummary, Error>
    func parseRechargesSummary(html: String) -> Result<RechargesSummary, Error>
    func parseTransfersSummary(html: String) -> Result<TransfersSummary, Error>
    func parseQuotesPaidSummary(html: String) -> Result<QuotesPaidSummary, Error>
    func parseConnections(html: String) -> Result<[Connection], Error>
    func parseRecharges(html: String) -> Result<[Recharge], Error>
    func parseTransfers(html: String) -> Result<[Transfer], Error>
    func parseQuotesPaid(html: String) -> Result<[QuotePaid], Error>
}