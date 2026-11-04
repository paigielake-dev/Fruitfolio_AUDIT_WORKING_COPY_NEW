# User page editor lifetime and imported-media protection

The editor now cancels pending photo loading on actual disappearance, protects interactive dismissal during an import, silently handles intentional task cancellation, and removes only its unreferenced draft bytes. Saved pages and shared imported images retain ownership. Added a persistence/restart test for image replacement, old-byte removal, independent live drafts, and exact saved image identity. Runtime execution pending; existing photo-picker journey retained unchanged.
