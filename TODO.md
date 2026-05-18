# TODO - Auth/Profile boot sequence fixes

## Completed
- [x] Repo inspected: AuthProvider + UserHomeScreen + GlassTopBar.

## Next steps (to implement)
- [ ] Fix splash/initialization gating so /home never renders until AuthProvider finishes storage restore + profile fetch.
- [ ] Add `isAuthInitialized` (and optional loading/error states) to AuthProvider.
- [ ] In main.dart, wrap routes (or provide redirect) based on auth initialization.
- [ ] In UserHomeScreen, stop relying on fallback 'User' while profile is still being restored.
- [ ] Remove/avoid 'User' default fallback in GlassTopBar; instead show loading/skeleton or hide welcome until first_name is real.
- [ ] Add debug logs: token restore, profile fetch start/end, and notifyListeners triggers.

