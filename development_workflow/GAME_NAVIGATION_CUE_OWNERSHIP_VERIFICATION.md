# Correct-answer navigation and earned-star cues

The canonical catch-navigation control already owns its soft-pop. Its action no longer directly requests a second star chime before any star is banked. The existing gameplay observer still requests the chime when available star passes actually increase; original audio assets and playback/mute policy are unchanged.

Opt-in DEBUG AudioManager diagnostics now count actual star-chime requests in addition to existing soft-pop/open/close counters. The game regression route can expose these counters using the same real manager and private root preference suite. It configures only that disposable route's sound settings. Production diagnostic recording stays off.

Eight added Apple UI launches combine navigation versus actual star banking, global mute and Reduce Motion at accessibility XXXL. Navigation expects two canonical pops across answer/catch presses and zero star requests; actual star banking expects one pop and one event chime. Accepted AVAudioPlayer.play() starts are checked separately for muted/unmuted pops. These scenarios are NOT_RUN without Apple SDK. No request count is presented as physical audibility, listening or animation verification.

Linux parser, genuine SwiftSyntax ownership checks and portable/native/workflow results are recorded separately. They do not compile or execute AVFoundation/SwiftUI. All artwork and original audio payloads remain unchanged.
