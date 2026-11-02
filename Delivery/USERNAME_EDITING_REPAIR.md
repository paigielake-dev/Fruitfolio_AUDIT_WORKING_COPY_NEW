# Shared username typing repair

Prompt1B sections 6F and 19X require one shared Account/Fruit Basket username. Inspection found the leaderboard TextField bound directly to the validated authority: entering the first or second character was rejected and the field reverted, preventing ordinary typing from an empty value.

The field now retains a local editing draft, publishes only valid non-explicit usernames through the existing shared store, displays validation failures without replacing the last valid public identity, and counts the visible draft. Account and Fruit Basket still observe the same persistent authority. A Done keyboard action dismisses each username editor. Existing artwork and approved public-username policy are preserved.

The new actual-app UI journey types characters individually, saves in Account, verifies Fruit Basket receives the value, edits in Fruit Basket, verifies Account updates, and restarts the app. It is NOT VERIFIED until its actual macOS simulator run completes. No global reservation or real-name detection is claimed: worldwide registration still requires the configured authenticated service, and the application has no authoritative legal-name identity against which to compare a pseudonym.
