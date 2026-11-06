# Toggle/volume labels and selected-locale percentages

The actual WatercolorToggle now uses independent shared protected display state
for its app-generated label and on/off accessibility value. Changing the Boolean
immediately selects the new source key, so a previous translated value cannot
remain as the current state. The actual Toggle and existing custom style remain;
there are no nested buttons/disclosures. Binding mutation still precedes the one
press-cue callback, preserving the behavior that enabling sound effects can play
its own accepted cue while global mute still suppresses playback. Machine/source/
unavailable states are explicit in label captions and accessibility metadata.

The actual settings volume row uses the same label state. Its slider now has an
explicit 44pt minimum control frame, instead of relying on the height of the whole
label/slider VStack. Selected-language Foundation number formatting produces its
accessibility percentage; values are never fed through machine translation. The
original 0...1 preference remains unchanged. Display rounds to whole percentages;
nonfinite or out-of-range values report unavailable instead of trapping through
Int conversion or inventing a valid zero. This is preference presentation, not
measurement-unit conversion or a change to saved volume semantics.

Three actual Foundation methods test English/French/Arabic digits/symbols, bounds,
rounding and invalid values, plus private SettingsStore persistence/reload after
formatting. A DEBUG readback reads actual UserDefaults effects fields through the
store's existing keys; it is not simulated storage or a health-data diagnostic.

The new registered DEBUG -fruitfolioSettingsControlsQA route uses the existing
shell's disposable preferences/context authorities and actual SettingsStore,
AudioManager, MotionPreferences, Toggle and volume row. It seeds before showing
controls, has no production navigation/export path, and reads actual saved effects
and volume. Forced RTL requires both that route and its RTL modifier, without
changing production language authority. English fixture labels test layout only.
Eight Apple launch scenarios cover mute x motion override x LTR/RTL at Accessibility
XXXL. They check off/on value, 44pt controls, one requested soft pop, accepted
playback under mute rules, actual saved-value readback, slider adjustment and
screenshots. AVAudioPlayer acceptance is not physical listening evidence.

Apple SDK/SwiftUI typechecking, Combine binding/observation, toggle/slider behavior,
VoiceOver, visible bounds/RTL, audio and screenshots remain NOT_RUN. Official
MADLAD resources, genuine linguistic/clinical accuracy and device performance also
remain blocked/open. Existing Foundation/native tests do not close those gates.

Final feasible verification: 694 portable XCTest +21 Swift Testing; 707 native CPU XCTest +21 Swift Testing; 42 workflow checks (including registered QA shell isolation); 302 compiler-parsed Swift files; zero actual SwiftSyntax sound ownership findings. Apple and official model/quality gates remain NOT_RUN.
