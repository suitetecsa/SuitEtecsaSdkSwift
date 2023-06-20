import Foundation
import SwiftSoup

public extension Document {
    func throwExceptionOnFailure(msg: String, portal: Portal) throws {
        var errors = [String]()

        do {
            if let lastScript = try self.select("script[type='text/javascript']").last() {
                let failReason = [
                    Portal.ConnectPortal: "alert\\(\"(?<reason>[^\"]*?)\"\\)",
                    Portal.UserPortal: "toastr\\.error\\('(?<reason>.*)'\\)"
                ]
                if let regex = try? NSRegularExpression(pattern: failReason[portal]!, options: []) {
                    let range = NSRange(location: 0, length: lastScript.data().trimmingCharacters(in: .whitespacesAndNewlines).count)
                    if let match = regex.firstMatch(in: lastScript.data().trimmingCharacters(in: .whitespacesAndNewlines), options: [], range: range) {
                        let reasonRange = match.range(at: 1)
                        let reason = (lastScript.data().trimmingCharacters(in: .whitespacesAndNewlines) as NSString).substring(with: reasonRange)
                        if portal == Portal.ConnectPortal {
                            throw NautaException.genery(message: "\(msg) :: \(reason)")
                        } else {
                            let error = try SwiftSoup.parse(reason)
                            let errorText = try error.text()
                            if errorText.starts(with: "Se han detectado algunos errores.") {
                                let subMessages = try error.select("li[class='sub-message']")
                                try subMessages.forEach { subMessage in
                                    errors.append(try subMessage.text())
                                }
                                throw NautaException.genery(message: "\(msg) :: \(errors.joined(separator: ", "))")
                            } else {
                                throw NautaException.genery(message: "\(msg) :: \(errorText)")
                            }
                        }
                    }
                }
            }
        } catch Exception.Error(_, let message) {
            throw NautaException.genery(message: "\(msg) :: \(message)")
        } catch NautaException.genery(let message) {
            throw NautaException.genery(message: message)
        } catch {
             throw NautaException.genery(message: "\(msg) :: \(error.localizedDescription)")
        }
    }
}