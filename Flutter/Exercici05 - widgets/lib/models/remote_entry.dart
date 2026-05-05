class RemoteEntry {
  const RemoteEntry({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.size,
    required this.permissions,
    required this.userId,
    required this.groupId,
    required this.modifiedAt,
  });
  

  final String name;
  final String path;
  final bool isDirectory;
  final int? size;
  final String permissions;
  final int? userId;
  final int? groupId;
  final DateTime? modifiedAt;
}

String formatBytes(int? bytes) {
  if (bytes == null) {
    return '-';
  }
  if (bytes < 1024) {
    return '$bytes B';
  }
  final kb = bytes / 1024;
  if (kb < 1024) {
    return '${kb.toStringAsFixed(1)} KB';
  }
  final mb = kb / 1024;
  if (mb < 1024) {
    return '${mb.toStringAsFixed(1)} MB';
  }
  final gb = mb / 1024;
  return '${gb.toStringAsFixed(1)} GB';
}
