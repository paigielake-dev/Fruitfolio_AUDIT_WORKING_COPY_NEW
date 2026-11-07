# Actual rare-star spawner integration

Both actual physical/classification spawners now receive their star-planner unit draw through an optional MainActor initializer dependency. Its default is exactly the existing Double.random(in:0...1); unrelated random choices remain unchanged. There is no UI toggle, persisted seed or altered rarity policy. The unchanged planner still requires eight fruit drops and a draw below0.05.

Three new actual-controller regressions use fixed controlled draws, not flaky frequency sampling. They verify classification spacing/reset across two passed stars, physical spacing then an actual standalone-star mouth/transit/settlement granting one pass with zero fruit/score, and exclusion at the exact probability upper boundary in both modes. Physical probes discard unselected fruit presentations to isolate star behavior and use the shared frame/physics driver with virtual dates; they are not live wall-clock/GUI performance measurements or statistical distribution evidence.

The focused actual persistence/controller suite executed33 cases successfully. Final full supported results are recorded with the batch/checklist evidence. Existing default-randomness controller tests and separate-event conservation remain in those full suites.

Original planner constants, masks/artwork, engine, persistence and catalog are unchanged. Genuine Apple object/marker/rarity presentation, gestures/VoiceOver/audio/device balance/performance and official MADLAD/native-language/clinical verification remain open. Controlled boundary tests do not certify all randomness quality or any whole original checklist requirement.
