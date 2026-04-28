// lib/widgets/users/user_utils.dart

int toInt(dynamic v) {
  if (v == null) return 0;
  return (v as num).toInt();
}

bool isArchived(dynamic user) {
  final val = user['is_archived'];
  return val == true || val == 1 || val == 'true';
}

bool isActive(dynamic user) {
  final val = user['is_active'];
  return val == true || val == 1 || val == 'true';
}