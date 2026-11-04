# Identity-bound popup dismissal

Corrected a shared popup race: a delayed completion checked only “dismissing,” so a late callback could finish a different newer popup. Completion now requires the actual original popup identity and a requested dismissal. The host uses a cancellation-aware identity-bound task, including host reconstruction, while popup-close audio stays tied to the actual state transition. Added a replacement/guarded-acknowledgement/stale-callback test. No popup wording, artwork, priority, or destructive action changed; execution pending.
