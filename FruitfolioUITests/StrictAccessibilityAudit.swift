import XCTest

extension XCTestCase {
    /// Record the actual failing element, then let XCTest report every issue.
    /// Returning false is unconditional: no type, label or issue is suppressed.
    func fruitfolioStrictAccessibilityAudit(_ app: XCUIApplication) throws {
        try app.performAccessibilityAudit(for: .all) { issue in
            var record: [String: Any] = [
                "auditType": issue.auditType.rawValue,
                "compactDescription": issue.compactDescription,
                "detailedDescription": issue.detailedDescription,
                "suppressed": false
            ]
            if let element = issue.element, element.exists {
                record["elementIdentifier"] = element.identifier
                record["elementLabel"] = element.label
                record["elementFrame"] = String(describing: element.frame)
                record["elementDescription"] = element.debugDescription
            }
            let data = try JSONSerialization.data(withJSONObject: record, options: [.prettyPrinted, .sortedKeys])
            let text = String(decoding: data, as: UTF8.self)
            print("STRICT_ACCESSIBILITY_ISSUE: " + text)
            let attachment = XCTAttachment(string: text)
            attachment.name = "StrictAccessibilityIssue_\(issue.auditType.rawValue)"
            attachment.lifetime = .keepAlways
            self.add(attachment)
            // Audit may scroll to another element. Capture that actual viewport,
            // rather than infer its appearance from the pre-audit screenshot.
            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = "StrictAccessibilityIssueViewport_\(issue.auditType.rawValue)"
            screenshot.lifetime = .keepAlways
            self.add(screenshot)
            return false
        }
    }
}
