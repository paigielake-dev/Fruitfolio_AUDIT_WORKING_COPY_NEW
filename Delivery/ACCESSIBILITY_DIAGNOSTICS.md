# Strict accessibility diagnostics

Run29 and Run35 contain actual contrast/text-clipping audit failures. They remain failures. The screenshot for Run35's large Contact control visually contains burgundy text on the original pale painted pill, but that visual observation does not overrule XCTest or establish the source of its reported issue.

The next test revision records each audit issue's native type, descriptions, actual element label/identifier/frame and element hierarchy as an attachment and in the test log. The issue handler returns `false` unconditionally, preserving XCTest's reporting of every issue. No audit type, label, color, element or issue is filtered or accepted as an exception.

The diagnostic implementation uses Apple's `XCUIAccessibilityAuditIssue` properties and `performAccessibilityAudit(for:_:)` API:
https://developer.apple.com/documentation/xcuiautomation/xcuiaccessibilityauditissue
https://developer.apple.com/documentation/xcuiautomation/xcuiapplication/performaccessibilityaudit(for:_:)

These additional diagnostics have not yet executed. Their source is not proof that any contrast, clipping, VoiceOver or other accessibility requirement passes.
