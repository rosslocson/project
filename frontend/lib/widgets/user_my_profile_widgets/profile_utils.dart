// lib/widgets/user_profile/profile_utils.dart

String getProfileVal(Map<String, dynamic>? user, String key) {
  final v = user?[key];
  if (v == null) return '—';
  final s = v.toString().trim();
  return s.isEmpty ? '—' : s;
}