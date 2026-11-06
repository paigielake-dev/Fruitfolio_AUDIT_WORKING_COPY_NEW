# Question delivery and history acknowledgement

A provider response/error is current only while its task/topic/difficulty/screen/generation still match and the game store remains writable. After structural/source-topic validation, the actual controller now confirms the history write before exposing the new question or clearing its answer selection. Failed history acknowledgement leaves the question hidden and returns the owned loading phase to setup. No original external data is restored automatically.

The existing store recordQuestion API returns a discardable acknowledgement Boolean. Its disk adapter, schema, scientific/source validation and provider content remain unchanged. Context checks continue to guard both typed provider errors and general failures.

Four new deterministic actual actor/controller tests hold provider completion using checked continuations: external deletion then protection before success, rejected history write, external deletion before provider error, and acknowledged success followed by reopening the actual store. They use private defaults/nonclinical fixtures and no timing sleeps. Existing background, changed-topic and cancellation regressions remain. The seven-case pre-fix ownership suite reproduced six failed assertions.

The positive case verifies actual question display state, selected-answer reset, persisted history surviving reopen, and unchanged bytes on read-only reopen. Negative cases verify no question/error publication, no history cache advance and preserved original or externally deleted bytes. These Foundation assertions are not Apple UI/Combine acceptance or clinical/source approval of fixture content.

Final supported results are attached to matching batch/checklist evidence. Apple native provider/loading/recovery presentation, background/queued UI and physical-device checks plus official MADLAD/native-language/clinical review remain unexecuted. No whole checklist item is certified.
