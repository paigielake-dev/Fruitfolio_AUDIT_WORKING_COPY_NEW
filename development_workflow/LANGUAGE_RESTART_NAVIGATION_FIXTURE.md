# Language restart and recognizable-selector verification

A new DEBUG route hosts the actual Settings menu and FAQ under the existing shell SettingsStore, locale and layout-direction environment. The selected language is never forced in this fixture. Menu options retain native language names and now have stable identifiers. Production selection, navigation and preferences behavior are unchanged.

A strict UUID token can select only a `fruitfolio.uiQA.languageRestart.<UUID>` private preferences suite. Normal regression owners keep their previous automatic cleanup behavior. Only this explicit restart fixture survives owner release; it has explicit cleanup and an actual cleanup launch. Arbitrary domain names and production preference domains are not accepted. No synchronize/fsync call is added to simulate production durability.

Three Foundation cases verify same-process owner/store recreation with retained language, explicit cleanup, isolated independent domains and token validation. These do NOT verify an operating-system process restart. Existing default-owner release/cleanup regressions remain unchanged.

Four new Apple UI vectors use French/Arabic and Reduce Motion off/on at XXXL. Each selects a native-name item in the actual Settings menu, checks the actual saved preference, transitions the QA host to the actual FAQ and back, inspects the actual injected locale/direction, terminates/relaunches the app with the same private token, and cleans that domain in a final launch. This is twelve launches across four vectors, all NOT_RUN on Linux. QA-host screen transitions are not full production-router/back-stack acceptance. Genuine Apple notifications, native menu identifiers/pronunciation, persistence after process termination and production navigation remain external verification.

The on-device translation inference is paused only in the QA route for deterministic source/catalog fallback; this does not establish French/Arabic machine translation quality. Official MADLAD/model/tokenizer/clinical/device verification remains open. No original398/399 is certified from fixture code or same-process tests.
