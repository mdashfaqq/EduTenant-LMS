import 'package:intl/intl.dart';
String formatDate(String? value, {String fallback = 'N/A'}) {
  if (value == null || value.isEmpty) {
    return fallback;
  }

  final parsed = DateTime.tryParse(value);
  if (parsed == null) return fallback;

  return DateFormat('dd MMM yyyy, hh:mm a').format(parsed.toLocal());
}
String formatRelativeTime(String? value, {String fallback = 'Unknown'}) {
  if (value == null || value.isEmpty) {
    return fallback;
  }

  final parsed = DateTime.tryParse(value)?.toLocal();
  if (parsed == null) {
    return fallback;
  }

  final now = DateTime.now();
  final diff = now.difference(parsed);

  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';

  // ✅ fallback to formatted date
  return DateFormat('dd MMM yyyy').format(parsed);
}
