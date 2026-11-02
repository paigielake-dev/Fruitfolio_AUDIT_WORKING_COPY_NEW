# Bounded asynchronous imported-image display

Removed full-resolution UIImage decoding from every page/editor body evaluation. Imported photos now decode to a bounded display-only preview on a cancellable worker task, once per immutable image identity, while their original stored bytes remain unchanged and no derivative file is persisted. Image orientation is retained by ImageIO. A missing/unreadable image produces an explicit error and still leaves its removal control reachable instead of silently hiding the attachment.

Added a real ImageIO decode test checking pixel bounds, aspect ratio, exact original byte preservation, no derivative files, and corrupt-image preservation. Existing normal/largest two-photo/save/edit/restart journeys remain the behavioral regression checks. Compilation, runtime memory/frame measurements and visual acceptance for this batch are pending; no performance PASS is inferred from code alone.
