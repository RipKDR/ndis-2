class UserProfile {
  final String uid;
  final String? displayName;
  final String? email;
  final String role; // 'participant' | 'provider' | ''
  final DateTime? createdAt;

  UserProfile({
    required this.uid,
    required this.role,
    this.displayName,
    this.email,
    this.createdAt,
  });

  UserProfile copyWith({String? role, String? displayName, String? email}) => UserProfile(
        uid: uid,
        role: role ?? this.role,
        displayName: displayName ?? this.displayName,
        email: email ?? this.email,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'displayName': displayName,
        'email': email,
        'role': role,
        'createdAt': createdAt?.toIso8601String(),
      };

  static UserProfile fromMap(Map<String, dynamic> m) => UserProfile(
        uid: m['uid'] as String,
        displayName: m['displayName'] as String?,
        email: m['email'] as String?,
        role: (m['role'] as String?) ?? '',
        createdAt: m['createdAt'] != null ? DateTime.tryParse(m['createdAt'] as String) : null,
      );
}

