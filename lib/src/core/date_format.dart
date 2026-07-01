import 'package:intl/intl.dart';

/// Format tanggal untuk UI aplikasi GPI Yehuda.
/// Menggunakan format dd/MM/yyyy sesuai permintaan klien.
String formatTanggal(DateTime? date, {bool includeTime = false}) {
  if (date == null) return '-';
  final datePart = DateFormat('dd/MM/yyyy').format(date);
  if (!includeTime) return datePart;
  final timePart = DateFormat('HH:mm').format(date);
  return '$datePart $timePart WITA';
}

/// Parse string ISO8601 ke DateTime lalu format ke dd/MM/yyyy.
/// Tambahkan includeTime=true jika perlu menampilkan jam:menit WITA.
String formatTanggalString(String? dateStr, {bool includeTime = false}) {
  if (dateStr == null || dateStr.isEmpty) return '-';
  final parsed = DateTime.tryParse(dateStr);
  if (parsed == null) return dateStr;
  return formatTanggal(parsed.toUtc().add(const Duration(hours: 8)), includeTime: includeTime);
}

/// Format DateTime ke ISO8601 tanpa milisecond (untuk payload API).
String formatDateApi(DateTime? date) {
  if (date == null) return '';
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}T${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}Z';
}

/// Format DateTime ke yyyy-MM-dd (untuk input/date picker label).
String formatDateLabel(DateTime? date) {
  if (date == null) return '-';
  return DateFormat('yyyy-MM-dd').format(date);
}
