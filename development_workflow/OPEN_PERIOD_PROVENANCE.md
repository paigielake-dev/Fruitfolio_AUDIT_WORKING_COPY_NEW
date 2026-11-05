# Reported open episode versus today's observation

An onboarding answer that a period is currently open used to produce the same Today state as a bleeding observation on today's civil date, indefinitely. The state now distinguishes a `reportedOpenPeriod` from bleeding recorded today. An open episode remains user-reported until the user updates it; no duration cutoff, end date, diagnosis or new daily bleeding record is inferred. A supplied future start, missing supplied-start state or supplied end cannot support an open-episode claim.

The Today caption gives explicit provenance and takes precedence over the wheel's general biological-region caption for reported episodes/actual bleeding. Both use the existing serious semantic/translation renderer. The original report and all historical source records remain unchanged. The state carries the open-episode flag separately from the actual-observation flag.

Bleeding alone, including spotting, does not establish menstruation. Body Biology stays general unless today's observation accompanies a reported open period or explicit recorded cycle day one. No pregnancy/ovulation/fertility status is inferred. Unlogged subsequent days return to the reported-open state without manufacturing observations. This is a source-provenance distinction, not a clinical validation that a reported episode is menstruation.

Regression tests use the actual cycle/onboarding stores and Today loader to compare before, same-day observed, and next-day states. Ended/future episodes and typed biology routing are covered. Apple screen rendering, VoiceOver and iOS refresh paths remain NOT RUN in Linux.
