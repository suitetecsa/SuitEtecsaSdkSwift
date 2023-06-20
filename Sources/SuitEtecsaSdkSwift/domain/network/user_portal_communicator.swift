import Foundation

public protocol UserPortalCommunicator {
    var csrf: String { get set }
    func loadCsrf(action: Action) async -> Result<String, Error>
    func getCaptcha() async -> Result<Data, Error>
    func login(username: String, password: String, captchaCode: String) async -> Result<String, Error>
    var userInformation: Result<String, Error> { get async }
    func topUp(rechargeCode: String) async -> Result<String, Error>
    func transfer(amount: Float, password: String, destinationAccount: String?) async -> Result<String, Error>
    func changePassword(oldPassword: String, newPassword: String) async -> Result<String, Error>
    func changeEmailPassword(oldPassword: String, newPassword: String) async -> Result<String, Error>
    func getConnectionsSummary(year: Int, month: Int) async -> Result<String, Error>
    func getRechargesSummary(year: Int, month: Int) async -> Result<String, Error>
    func getTransfersSummary(year: Int, month: Int) async -> Result<String, Error>
    func getQuotesPaidSummary(year: Int, month: Int) async -> Result<String, Error>
    func getConnections(connectionsSummary: ConnectionsSummary, large: Int, reversed: Bool) async -> Result<[String], Error>
    func getRecharges(rechargesSummary: RechargesSummary, large: Int, reversed: Bool) async -> Result<[String], Error>
    func getTransfers(transfersSummary: TransfersSummary, large: Int, reversed: Bool) async -> Result<[String], Error>
    func getQuotesPaid(quotesPaidSummary: QuotesPaidSummary, large: Int, reversed: Bool) async -> Result<[String], Error>
}