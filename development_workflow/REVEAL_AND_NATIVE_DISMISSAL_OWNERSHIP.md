# Reveal cancellation and native dismissal ownership

A task already cancelled before continuing a successful reveal must not consume the accepted result or advance its session. The actual controller now checks Task.isCancelled before identity rotation, screen changes or round increment. The new genuine-controller regression creates a successful round through settled catches, cancels its own continuation task, checks the entire session/ledger/result/ticket/progress, and then proves a fresh request can still continue. The pre-fix run executed one test and produced four failed assertions.

The game root keeps the frozen pending save payload until actual native onDismiss. That nonnil payload now keeps the interaction gate closed even after showingSaveDestination becomes false, covering the closing interval. Save requires the current successful basket reveal and matching ledger; topic/difficulty/reset and continuation callbacks use the same ownership gate. No pending payload is regenerated from later live content.

Native onDismiss clears ownership, then yields once before returning accessibility focus to the Save trigger only if the same question/round still owns the active visible reveal, with no new popup/sheet. Disappearance/background clears that focus. No arbitrary delay, automatic save or background focus request is introduced.

Final supported test results are attached to the batch/checklist entries. Genuine Apple SDK typechecking, actual native closing/reentry ordering, VoiceOver focus return, keyboard and background/device behavior remain NOT RUN. The written four-vector actual-root save UI matrix is not a Linux pass and does not establish French translation or official MADLAD inference.
