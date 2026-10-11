class AppGroup {
  const AppGroup({
    required this.id,
    required this.name,
    required this.isPersonal,
    this.inviteCode,
    this.status = 'active',
    this.createdAt,
  });

  final String id;
  final String name;
  final bool isPersonal;

  /// Mã 8 ký tự để mời người khác vào nhóm. Null với nhóm cá nhân.
  final String? inviteCode;

  final String status;
  final DateTime? createdAt;

  bool get isShared => !isPersonal;

  factory AppGroup.fromMap(Map<String, dynamic> map) {
    final d = map['created_at'];
    return AppGroup(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      isPersonal: map['is_personal'] as bool? ?? true,
      inviteCode: map['invite_code'] as String?,
      status: map['status'] as String? ?? 'active',
      createdAt: d != null
          ? (d is DateTime ? d : DateTime.parse(d.toString()))
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AppGroup && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
