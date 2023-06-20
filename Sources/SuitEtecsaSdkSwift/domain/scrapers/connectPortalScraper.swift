public protocol ConnectPortalScraper {
    func parseErrors(html: String) -> Result<String, Error>
    func parseCheckConnections(html: String) -> Bool
    func parseActionForm(html: String) -> Result<(url: String, form: [String: String]), Error>
    func parseLoginForm(html: String) -> Result<(url: String, form: [String: String]), Error>
    func parseNautaConnectInformation(html: String) -> Result<NautaConnectInformation, Error>
    func parseRemainingTime(html: String) -> Result<String, Error>
    func parseAttributeUUID(html: String) -> Result<String, Error>
    func isSuccessLogout(html: String) -> Bool
}