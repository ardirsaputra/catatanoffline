import 'package:intl/intl.dart';

class DateFormatter {
  static final _fullFormat = DateFormat('dd MMMM yyyy', 'id_ID');
  static final _shortFormat = DateFormat('dd/MM/yyyy', 'id_ID');
  static final _timeFormat = DateFormat('HH:mm', 'id_ID');
  static final _fullWithTime = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
  static final _fileNameFormat = DateFormat('yyyyMMdd_HHmmss');

  static String formatFull(DateTime date) => _fullFormat.format(date);
  static String formatShort(DateTime date) => _shortFormat.format(date);
  static String formatTime(DateTime date) => _timeFormat.format(date);
  static String formatFullWithTime(DateTime date) =>
      _fullWithTime.format(date);
  static String formatForFileName(DateTime date) =>
      _fileNameFormat.format(date);

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return _fullFormat.format(date);
  }
}
