String normalizeRoleValue(String? role) {
  final normalized = role?.trim().toLowerCase() ?? '';
  if (normalized.isEmpty) {
    return '';
  }
  return normalized.replaceAll(RegExp(r'[\s-]+'), '_');
}

String roleLabel(String? role) {
  final normalized = normalizeRoleValue(role);
  switch (normalized) {
    case 'platform_admin':
      return 'Platform Admin';
    case 'admin':
      return 'Admin';
    case 'instructor':
      return 'Instructor';
    case 'student':
      return 'Student';
    case 'parent':
      return 'Parent';
    default:
      final raw = role?.toString().trim();
      return raw == null || raw.isEmpty ? 'Student' : raw;
  }
}
