class PresenceHelper {
  static void setupHooks(String userId, Function(bool isVisible) onVisibilityChanged) {
    // No-op on mobile platforms, handled via WidgetsBindingObserver in PresenceService.
  }
}
