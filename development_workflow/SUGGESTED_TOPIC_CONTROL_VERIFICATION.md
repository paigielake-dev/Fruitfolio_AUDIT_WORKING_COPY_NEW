# Suggested topic controls

The existing two-column topic grid now delegates to the canonical pill control rather than keeping a second raw button, local cue and shrinking two-line label. It retains the original pill artwork and 0.72 artwork opacity; only artwork dims, not text. Labels use the shared catalog/MADLAD presentation and can wrap without a line limit. The callback still sends the original source string to `chooseSuggestedTopic`, preserving existing research topic semantics. No typed topic is translated or rewritten.

Four added Apple UI launch scenarios request accessibility XXXL with motion and RTL combinations. They check long-label geometry and original source-topic readback. They are NOT_RUN without the Apple SDK. The earlier debug fixture referenced a nonexistent `.setup` screen case; it now calls the existing production `openSetup()` method. Swift parser success had not detected that type error.

Linux verification results are recorded in the batch run log. Apple SDK typechecking, screenshots, text clipping, physical sound, VoiceOver, translated-language geometry and device behavior remain unverified. This batch does not claim official MADLAD model or clinical translation approval.
