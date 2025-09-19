enum InviteStatus { pending, accepted, rejected }

class ProjectInvite {
  final String id;
  final String projectId;
  final String email; // invited user's email
  final String invitedBy; // leader user id
  final DateTime sentAt;
  final InviteStatus status;
  final DateTime? respondedAt;

  const ProjectInvite({
    required this.id,
    required this.projectId,
    required this.email,
    required this.invitedBy,
    required this.sentAt,
    this.status = InviteStatus.pending,
    this.respondedAt,
  });

  factory ProjectInvite.fromJson(Map<String, dynamic> json) => ProjectInvite(
        id: json['id'] ?? '',
        projectId: json['projectId'] ?? '',
        email: json['email'] ?? '',
        invitedBy: json['invitedBy'] ?? '',
        sentAt: DateTime.parse(
          json['sentAt'] ?? DateTime.now().toIso8601String(),
        ),
        status: InviteStatus.values.firstWhere(
          (e) => e.toString().split('.').last == json['status'],
          orElse: () => InviteStatus.pending,
        ),
        respondedAt:
            json['respondedAt'] != null ? DateTime.parse(json['respondedAt']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'email': email,
        'invitedBy': invitedBy,
        'sentAt': sentAt.toIso8601String(),
        'status': status.toString().split('.').last,
        'respondedAt': respondedAt?.toIso8601String(),
      };
}
