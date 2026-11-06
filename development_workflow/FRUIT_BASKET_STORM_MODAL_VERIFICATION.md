# Storm note modal scope and logical cue ownership

The existing storm note now declares modal scope, focuses its actual semantic heading, restores heading focus after foreground return and returns focus to the classification progress or pause control after guarded dismissal. Close, acknowledge and accessibility escape use the same existing pause/resume dismissal path. The same storm-key guard still prevents reopening on resume.

Opening/closing audio now follows logical showStormNote transitions, including a forced logical close, rather than selected call sites. Close-control and acknowledge button pops remain owned by their canonical controls. Serious question context uses a neutral rain-obstacle heading and hides the playful character; weather/obstacle/catching behavior and normal wording/art remain.

Private diagnostics now follow an actual overlay-visibility preference from the real game view, not a guess from completion/game state. While an overlay owns the screen, its diagnostic counters live inside that scope; after dismissal the observed normal readback returns. No production telemetry or user/health input is added.

Twelve Apple UI launches cover normal/serious and close/acknowledge/shared escape callback, each in normal-LTR-unmuted versus reduced-RTL-muted modes. They background/reactivate, require one logical open/close, check background exclusion and resumed classification. This is not a full independent three-way settings cross product, actual VoiceOver escape dispatch or physical audibility/focus proof. Apple SDK/typecheck/UI/animation/geometry/VoiceOver checks remain NOT_RUN.

One English-only neutral heading brings the catalog from 731 to 732 with every previous entry preserved; foreign translation review remains absent. Feasible Linux results are recorded in the batch log and do not establish UIKit/AVFoundation behavior. Original assets and scientific/source records remain unchanged.
