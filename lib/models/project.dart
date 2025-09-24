enum ProjectStatus { planning, active, onHold, completed, cancelled }

class Project {
  final String id;
  final String name;
  final String description;
  final ProjectStatus status;
  final DateTime createdAt;
  final DateTime? dueDate;
  final List<String> teamMembers;
  final double progress; // 0.0 to 1.0
  final String createdBy;
  final bool archived;

  Project({
    required this.id,
    required this.name,
    required this.description,
    this.status = ProjectStatus.planning,
    required this.createdAt,
    this.dueDate,
    this.teamMembers = const [],
    this.progress = 0.0,
    required this.createdBy,
    this.archived = false,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      status: ProjectStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => ProjectStatus.planning,
      ),
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      teamMembers: List<String>.from(json['teamMembers'] ?? []),
      progress: (json['progress'] ?? 0.0).toDouble(),
      createdBy: json['createdBy'] ?? '',
      archived: (json['archived'] ?? false) == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'teamMembers': teamMembers,
      'progress': progress,
      'createdBy': createdBy,
      'archived': archived,
    };
  }

  Project copyWith({
    String? id,
    String? name,
    String? description,
    ProjectStatus? status,
    DateTime? createdAt,
    DateTime? dueDate,
    List<String>? teamMembers,
    double? progress,
    String? createdBy,
    bool? archived,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      teamMembers: teamMembers ?? this.teamMembers,
      progress: progress ?? this.progress,
      createdBy: createdBy ?? this.createdBy,
      archived: archived ?? this.archived,
    );
  }
}
