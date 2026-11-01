# Grounding repair — ongoing verification

Run12's two native drafts both copied the literal schema placeholder “one evidence-bounded claim” four times, copied the bridge placeholder and used the safety class “normal” as a limitation. The independent validator correctly rejected them. This was prompt/template contamination, not missing native inference or an evidence-ID decoding failure.

The prompt now separates instructions, actual extracts, question and metadata, and contains no fake example claim strings. The existing requirement that bridge/limitation are null is also enforced by grammar. The validator and retrieval/evidence acceptance rules are unchanged from the authoritative checkpoint.

Real Linux GGUF probes pass for an affirmative research statement and a negated ovulation statement, with exact evidence text and the correct IDs. These controlled fixture results do not establish clinical or APA accuracy for the entire corpus. Swift native tests now change question/evidence/ID between requests and still require the strict validator to accept each result. macOS/Xcode rerun is pending.

CI now attempts the focused hormone create/restart/edit/delete lifecycle before broad UI traversal and retains its result/screenshot artifact early. The long exploratory capture test runs last with a bounded duration; interruption must be recorded as incomplete, never as a behavior pass.
