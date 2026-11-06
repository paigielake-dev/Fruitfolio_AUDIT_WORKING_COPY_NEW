# Setup/session changes require acknowledged writes

Actual topic start now checks protection after creating progress, before constructing a session. Returning-topic reset stops on rejected reset acknowledgement and checks protection before session creation. Difficulty is assigned to the controller/session only after the preferred-difficulty commit is acknowledged. Level reset retains existing stop-clock behavior but does not rewrite session levels or navigate to setup when the progress reset fails.

The existing store reset/preference APIs now return discardable acknowledgement Booleans, matching updateProgress. Existing ignored-result callers remain valid; disk adapter/schema/source research/artwork are unchanged. Explicit reload still accepts disk and the UI returns to topic setup; there is no background retry or replay of a stale request.

Four actual-controller regressions inject dropped writes through private defaults for new-topic start, returning-topic reset, level reset, and difficulty change. The 22-case pre-fix persistence suite reproduced six assertion failures. Fresh explicit successful requests after reload verify level reset preserves score/highest level, and difficulty remains separate from game level/score. The paused level-six session is a domain fixture; it does not establish physical level-six obstacle gameplay.

Final supported results are recorded in the matching batch/checklist evidence. Apple Combine publication, native UI selection/recovery/queued-action behavior, physical-device gameplay and official MADLAD/native-language/clinical verification remain NOT RUN. Other preference consumers such as control-mode changes are independent follow-up work; this batch does not certify every consumer or whole original requirement.
