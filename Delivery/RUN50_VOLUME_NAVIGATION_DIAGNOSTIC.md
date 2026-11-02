# Actual Run50 volume journey failure

The real Simulator test failed at its first music drag: its value remained 35% after XCTest synthesized adjustment to 0.23. Other earlier runs passed this same actual native-slider journey. The new failure is retained, not dismissed as a pass.

Inspection found a concrete navigation flaw in the test helper. It first visits all four vertically stacked sliders, then returns to the first. Its `reach` helper always swiped upward whenever the slider was not fully in the visible area, even if that slider was already above the viewport. It asserted only isHittable and did not require the thumb and entire control to remain inside the owning scroll view before dragging. A partially visible control could pass that precondition.

The helper now chooses scroll direction from the actual target position, intersects with the real settings ScrollView, and requires the complete slider frame in that viewport. Failures capture the actual screenshot and full hierarchy. A short condition-based wait observes the native value after its touch event; unchanged values still fail. No app preference, artwork, native UISlider, category independence, restart, Master mute or enabled-state assertion is replaced or bypassed. Actual rerun is required before accepting this diagnosis as sufficient.
