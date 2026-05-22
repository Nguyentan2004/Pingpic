import 'dart:html' as html;

class PresenceHelper {
  static void setupHooks(String userId, Function(bool isVisible) onVisibilityChanged) {
    // 1. Listen to visibility change (e.g. user switches tabs, minimizes browser)
    html.document.onVisibilityChange.listen((event) {
      final isVisible = html.document.visibilityState == 'visible';
      onVisibilityChanged(isVisible);
    });

    // 2. Listen to pagehide/unload as fallback when user closes tab or navigates away
    html.window.onPageHide.listen((event) {
      onVisibilityChanged(false);
    });

    html.window.onBeforeUnload.listen((event) {
      onVisibilityChanged(false);
    });
  }
}
