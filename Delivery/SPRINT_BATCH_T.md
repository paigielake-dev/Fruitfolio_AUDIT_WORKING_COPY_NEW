# User-page photo presentation and large-text inside-book title

The editor now tracks actual system photo-picker presentation, so a temporary covering picker is not mistaken for ending the editing visit and cannot discard an earlier imported draft image. Real navigation still cancels imports and removes only unreferenced drafts. Normal and largest-text full user-page journeys now import a second real photo, verify both staged images survive, remove one, and retain existing save/edit/restart/guarded-delete assertions.

Found a real verification setup omission: the sprint workflow did not seed the simulator Photos library, although the original workflow did. It now installs the same original cloud fixture into the actual system library only when photo-import tests are selected; app state is not injected. This setup failure is separate from production photo behavior.

At accessibility sizes, the full dynamic inside-book title is placed below the unchanged decorative book instead of clipping/overflowing its fixed art. Normal composition is retained. Full continuous coded-book acceptance remains outstanding. All new runtime outcomes remain pending.
