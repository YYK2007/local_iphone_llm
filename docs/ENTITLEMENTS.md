# Optional Memory Entitlements (Advanced)

For larger on-device models, some iOS projects use these entitlements:
- `com.apple.developer.kernel.increased-memory-limit`
- `com.apple.developer.kernel.extended-virtual-addressing`

These may require provisioning/capability support on your team profile and can fail code signing if not allowed for your account/profile.

Use only after baseline app is already working.
