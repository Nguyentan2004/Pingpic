import 'package:intl/intl.dart';
import 'package:pingpic/l10n/app_localizations.dart';

/// Formats a [DateTime] into a dynamic relative time string or full date/time.
///
/// Rules:
/// - < 60 minutes: e.g., "5m ago", "12m ago" (or "Just now" if <= 0)
/// - >= 60 minutes and < 24 hours: e.g., "2h ago", "10h ago"
/// - >= 24 hours (1 day): e.g., "24/05/2026 • 14:32"
String formatMomentTime(DateTime createdAt, {AppLocalizations? l10n}) {
  final now = DateTime.now();
  final difference = now.difference(createdAt);

  if (difference.inMinutes < 60) {
    final minutes = difference.inMinutes;
    if (minutes <= 0) {
      return l10n != null ? l10n.notificationsJustNow : 'Just now';
    }
    return l10n != null ? l10n.notificationsMinutesAgo(minutes) : '${minutes}m ago';
  } else if (difference.inHours < 24) {
    final hours = difference.inHours;
    return l10n != null ? l10n.notificationsHoursAgo(hours) : '${hours}h ago';
  } else {
    final formatter = DateFormat('dd/MM/yyyy • HH:mm');
    return formatter.format(createdAt);
  }
}
