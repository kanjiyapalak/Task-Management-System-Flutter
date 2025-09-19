enum ProjectRole { leader, member }

class ProjectMember {
  final String userId;
  final String name;
  final String email;
  final ProjectRole role;
  final DateTime joinedAt;

  const ProjectMember({
    required this.userId,
    required this.name,
    required this.email,
    this.role = ProjectRole.member,
    required this.joinedAt,
  });

  factory ProjectMember.fromJson(Map<String, dynamic> json) => ProjectMember(
        userId: json['userId'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        role: ProjectRole.values.firstWhere(
          (e) => e.toString().split('.').last == json['role'],
          orElse: () => ProjectRole.member,
        ),
        joinedAt: DateTime.parse(
          json['joinedAt'] ?? DateTime.now().toIso8601String(),
        ),
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'name': name,
        'email': email,
        'role': role.toString().split('.').last,
        'joinedAt': joinedAt.toIso8601String(),
      };
}
