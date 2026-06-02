import 'package:intl/intl.dart';

/// Format a number as Indonesian Rupiah currency.
/// Example: 1500000 → "Rp 1.500.000"
String formatRupiah(num amount) {
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  return formatter.format(amount);
}

/// Format a number as short Rupiah.
/// Example: 1500000 → "Rp 1,5 jt"
String formatRupiahShort(num amount) {
  if (amount >= 1000000) {
    final juta = amount / 1000000;
    return 'Rp ${juta.toStringAsFixed(juta.truncateToDouble() == juta ? 0 : 1)} jt';
  } else if (amount >= 1000) {
    final ribu = amount / 1000;
    return 'Rp ${ribu.toStringAsFixed(ribu.truncateToDouble() == ribu ? 0 : 1)} rb';
  }
  return formatRupiah(amount);
}

/// Format budget range as "Rp X - Rp Y".
String formatBudgetRange(double? min, double? max) {
  if (min == null && max == null) return 'Harga belum ditentukan';
  if (min != null && max != null) {
    return '${formatRupiah(min)} - ${formatRupiah(max)}';
  }
  if (min != null) return 'Mulai ${formatRupiah(min)}';
  return 'Sampai ${formatRupiah(max!)}';
}

/// Format distance in km with proper Indonesian label.
String formatDistance(double? km) {
  if (km == null) return '';
  if (km < 1) return '${(km * 1000).toStringAsFixed(0)} m';
  return '${km.toStringAsFixed(1)} km';
}

/// Get Indonesian label for task status.
String getStatusLabel(String status) {
  switch (status.toLowerCase()) {
    case 'open':
      return 'Tersedia';
    case 'negotiating':
      return 'Negosiasi';
    case 'in_progress':
      return 'Dikerjakan';
    case 'completed':
      return 'Selesai';
    case 'cancelled':
      return 'Dibatalkan';
    default:
      return status;
  }
}

/// Get Indonesian label for task category.
String getCategoryLabel(String category) {
  switch (category.toLowerCase()) {
    case 'bersih-bersih':
      return 'Bersih-bersih';
    case 'pindahan':
      return 'Pindahan';
    case 'servis':
      return 'Servis';
    case 'tukang':
      return 'Tukang';
    case 'kurir':
      return 'Kurir';
    case 'lainnya':
      return 'Lainnya';
    default:
      return category;
  }
}

/// All available task categories.
const List<String> taskCategories = [
  'bersih-bersih',
  'pindahan',
  'servis',
  'tukang',
  'kurir',
  'lainnya',
];

/// Validate Indonesian phone number.
bool isValidPhone(String phone) {
  final regex = RegExp(r'^(\+62|62|0)8[1-9][0-9]{6,10}$');
  return regex.hasMatch(phone.replaceAll(' ', '').replaceAll('-', ''));
}

/// Format date in Indonesian locale.
String formatDate(DateTime dt) {
  return DateFormat('d MMMM yyyy', 'id').format(dt);
}

/// Format datetime in Indonesian locale.
String formatDateTime(DateTime dt) {
  return DateFormat('d MMM yyyy, HH:mm', 'id').format(dt);
}

/// Format time only.
String formatTime(DateTime dt) {
  return DateFormat('HH:mm').format(dt);
}
