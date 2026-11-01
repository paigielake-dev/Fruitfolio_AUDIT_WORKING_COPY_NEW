# Master audio control correction

Inspection found no persisted master-mute preference or Settings control. Disabling music/rain reduced loop volume but left the player running. The correction adds a persisted `allAudioMuted` preference, an accessible shared Settings toggle, and one master gate used by every application playback path. Existing per-category choices and volume preferences are retained.

Master mute pauses requested continuous players and stops one-shot/typing players. New playback requests remain suppressed. Unmuting resumes only enabled requested loops while the application is active and not interrupted; old one-shot cues are never replayed. Category disabling now physically pauses its loop. The existing explicit pause API also pauses the player and records its suspension until an explicit play/fade-in request.

Combine's newly delivered master value is cached by AudioManager before synchronization because Published emits before the Settings property is assigned. This prevents a stale preference from defeating the transition.

Real AVAudioPlayer tests cover all four categories, live volume updates, immediate muting, attempted playback during mute, selective resumption, startup from persisted mute and preservation of independent channel preferences. The Settings UI journey additionally toggles/restarts/restores the master control through the actual application. These new cases are NOT YET EXECUTED; no audible-quality or physical-device acceptance is claimed.
