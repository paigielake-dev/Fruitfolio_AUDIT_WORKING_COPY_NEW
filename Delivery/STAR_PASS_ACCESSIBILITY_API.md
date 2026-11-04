# Native star-pass announcements

The star-pass HUD uses UIKit UIAccessibility announcements when VoiceOver is running. The provisional accessibilityLiveRegion spelling was a cross-framework API mismatch and is removed before accepting its build; it is not a SwiftUI API. The actual native announcement preserves the banked/used action and exact count while the visible label/value remains accessible. No test or accessibility audit is suppressed. Source64 is superseded as an unaccepted diagnostic checkpoint; source65 requires its own actual Xcode build and tests.

Apple primary documentation: https://developer.apple.com/documentation/uikit/uiaccessibility/post(notification:argument:)
