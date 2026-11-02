# Encyclopedia/Guide metadata limits and non-explicit labels (Prompt 1B 4F)

The shared store now enforces 60-grapheme titles and 240-grapheme descriptions for both creation paths, renaming, and description editing. These implementation limits address the specified space constraint; the source specifies appropriate limits rather than exact numbers. Invalid edits fail before changing records, and error wording explicitly preserves the draft. Existing out-of-policy records are retained on load without truncation or deletion. Detail titles now scale and wrap instead of stopping at two lines.

A metadata-only local guardrail rejects common profanity/crude terms and direct violent-threat labels using whole-word boundaries. Legitimate sexual-health/anatomical terms remain allowed. It never moderates saved evidence, medical questions, clinical records, citations or independently authored page bodies. This is a conservative English guardrail, not a claim of comprehensive multilingual/contextual moderation; broader editorial acceptance remains PARTIAL.

Added creation/edit/restart/Unicode-boundary/legacy-preservation/medical-term/body-isolation tests. Apple execution pending.
