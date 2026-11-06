# Guide fixed-copy translation ownership

27 direct fixed/error text renderers and the remaining fixed branch labels in Guide popups and saved-page picker now use the existing FruitfolioTranslatedText owner. It uses catalog-first display, semantic rendering and the existing MADLAD service/fallback provenance. Fonts retain their original sizes and gain relative text styles. Destructive/error copy explicitly uses serious rendering. User titles, input bindings, source body policy, references and citations remain under their existing owners.

12 English keys were added; all 803 prior catalog entries compare unchanged. Production now has 815 keys and zero nonempty foreign-language units. The source receipt is RUN_LOGS/Guide-form-fixed-copy-preservation.json. No artwork/research/model resources changed.

50 actual workflow checks passed; all 311 Swift files parsed, Xcode references resolved and actual SwiftSyntax sound ownership reported no findings. This is a SwiftUI-only change; unchanged Foundation suites were not repeated. Last confirmed at parent 946d4c0: 773 portable XCTest, 795 native CPU XCTest, 21 Swift Testing cases per overlapping run.

Existing create/description UI cases now assert source fallback headings and readable error labels while retaining user drafts. All 52 Guide Apple UI launch cases remain NOT_RUN. Apple typecheck, callback/layout/accessibility acceptance, foreign translation accuracy and real official MADLAD inference are not established. TextField placeholder translation, remaining Guide screen copy, saved-status copy and dynamic user-content policy still require review. English RTL is layout-only, not language coverage.
