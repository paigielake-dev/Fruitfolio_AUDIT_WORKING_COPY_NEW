# Calendar load cancellation

The actual loader now checks cancellation before starting supplemental work, after onboarding/cycle snapshot reads, after prediction calculation, before and after awaiting supplemental results, and before publishing its return value. Existing actor journal recovery retains its consistency behavior; this change does not roll back acknowledged writes or claim to interrupt a synchronous prediction calculation midway.

The view captures the original month/context identity when creating its task and rejects cancelled/stale requests before setting loading state or invoking the loader. Existing final month/context acceptance checks remain. No prediction, source annotation, history or artwork calculation changed.

Two regressions use actual loader and isolated in-memory stores. A deterministic continuation holds the supplemental provider without sleeps. Pre-fix four-case focused suite had two failed assertions:pre-cancelled load started supplemental work; held-provider cancellation returned a snapshot. Hash receipt is RUN_LOGS/Calendar-cancellation-prior-failure.json. See batch verification for final executed suites.

Apple month-transition rendering, cancellation responsiveness with actual files/large histories, VoiceOver/Reduce Motion, device timing and full UI/runtime acceptance remain unverified. Linux storage/projection tests do not establish those results or official MADLAD inference.
