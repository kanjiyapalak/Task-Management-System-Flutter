import 'package:flutter/foundation.dart';
import '../models/project.dart';
import '../models/project_member.dart';
import '../models/project_invite.dart';
import '../models/task.dart';
import 'firebase_task_service.dart';
import 'firebase_auth_provider.dart';
import 'project_task_service.dart';
import 'invite_service.dart';
import 'firestore_project_service.dart';

class ProjectProvider extends ChangeNotifier {
  final AuthProvider authProvider;

  ProjectProvider({required this.authProvider}) {
    _init();
  }

  // State
  final List<Project> _projects = [];
  final Map<String, List<ProjectMember>> _membersByProject = {};
  final Map<String, List<ProjectInvite>> _invitesByProject = {};
  final Map<String, List<Task>> _tasksByProject = {};
  final Set<String> _tasksFetched = {};
  bool _loading = false;
  final FirebaseTaskService _firebaseTaskService = FirebaseTaskService();
  final ProjectTaskService _projectTaskService = ProjectTaskService();
  final InviteService _inviteService = InviteService();
  // Switch to Firestore for project persistence
  final FirestoreProjectService _fsProjectService = FirestoreProjectService();
  List<ProjectInvite> _myInvitesCache = [];

  // Getters
  bool get isLoading => _loading;
  List<Project> get projects => List.unmodifiable(_projects);
  List<ProjectMember> members(String projectId) =>
      List.unmodifiable(_membersByProject[projectId] ?? const []);
  List<ProjectInvite> invites(String projectId) =>
      List.unmodifiable(_invitesByProject[projectId] ?? const []);
  List<Task> tasks(String projectId) =>
      List.unmodifiable(_tasksByProject[projectId] ?? const []);

  // Derived
  Map<String, int> get stats {
    return {
      'total': _projects.length,
      'active': _projects
          .where((p) => p.status == ProjectStatus.active)
          .length,
      'planning': _projects
          .where((p) => p.status == ProjectStatus.planning)
          .length,
      'completed': _projects
          .where((p) => p.status == ProjectStatus.completed)
          .length,
      'onHold': _projects
          .where((p) => p.status == ProjectStatus.onHold)
          .length,
    };
  }

  // Actions
  Future<void> refresh() async {
    await _loadProjectsFromBackend();
  }

  Future<Project> createProject({
    required String name,
    required String description,
    DateTime? dueDate,
  }) async {
    final uid = authProvider.currentUser?.id;
    if (uid == null) {
      throw Exception('Please sign in to create a project');
    }
    final created = await _fsProjectService.createProject(
      name: name,
      description: description,
      createdBy: uid,
      dueDate: dueDate,
    );
    _projects.insert(0, created);
    _membersByProject[created.id] = [
      ProjectMember(
        userId: uid,
        name: authProvider.currentUser?.fullName ?? 'You',
        email: authProvider.currentUser?.email ?? 'you@example.com',
        role: ProjectRole.leader,
        joinedAt: DateTime.now(),
      ),
    ];
    _invitesByProject[created.id] = [];
    _tasksByProject[created.id] = [];
    notifyListeners();
    return created;
  }

  Future<void> deleteProject(String projectId) async {
    await _fsProjectService.deleteProject(projectId);
    _projects.removeWhere((p) => p.id == projectId);
    _membersByProject.remove(projectId);
    _invitesByProject.remove(projectId);
    _tasksByProject.remove(projectId);
    notifyListeners();
  }

  void sendInvites({
    required String projectId,
    required List<String> emails,
  }) {
    // Optimistic local add
    final list = _invitesByProject.putIfAbsent(projectId, () => []);
    final inviter = authProvider.currentUser?.id ?? 'leader_demo';
    final now = DateTime.now();
    for (final email in emails.where((e) => e.trim().isNotEmpty)) {
      list.add(ProjectInvite(
        id: 'tmp-${now.microsecondsSinceEpoch}-${email.hashCode}',
        projectId: projectId,
        email: email.trim(),
        invitedBy: inviter,
        sentAt: now,
        status: InviteStatus.pending,
      ));
    }
    notifyListeners();
    // Fire backend
    _inviteService.sendInvites(projectId: projectId, emails: emails);
  }

  Future<void> refreshInvitesForProject(String projectId) async {
    try {
      final raw = await _inviteService.getProjectInvites(projectId);
      final list = raw
          .map((j) => ProjectInvite(
                id: j['_id'] ?? '',
                projectId: (j['project'] is Map)
                    ? j['project']['_id']
                    : (j['project'] ?? projectId),
                email: j['email'] ?? '',
                invitedBy: j['invitedBy'] ?? '',
                sentAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
                status: InviteStatus.values.firstWhere(
                  (e) => e.toString().split('.').last == (j['status'] ?? 'pending'),
                  orElse: () => InviteStatus.pending,
                ),
                respondedAt: j['respondedAt'] != null
                    ? DateTime.tryParse(j['respondedAt'])
                    : null,
              ))
          .toList();
      _invitesByProject[projectId] = list;
      // Ensure accepted invites become members locally
      final members = _membersByProject.putIfAbsent(projectId, () => []);
      for (final inv in list.where((i) => i.status == InviteStatus.accepted)) {
        final exists = members.any((m) => m.userId == inv.email || m.email == inv.email);
        if (!exists) {
          members.add(ProjectMember(
            userId: inv.email, // use email as id placeholder
            name: inv.email.split('@').first,
            email: inv.email,
            role: ProjectRole.member,
            joinedAt: DateTime.now(),
          ));
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> ensureProjectTasksLoaded(String projectId) async {
    if (_tasksFetched.contains(projectId)) return;
    final fetched = await _projectTaskService.getProjectTasks(projectId);
    _tasksByProject[projectId] = fetched;
    _tasksFetched.add(projectId);
    _recomputeProjectProgress(projectId);
    notifyListeners();
  }

  Future<bool> assignTaskToMemberRemote({
    required String projectId,
    required String title,
    required String description,
    DateTime? dueDate,
    required String assignedUserId,
  }) async {
    final res = await _projectTaskService.assignTask(
      projectId: projectId,
      title: title,
      description: description,
      dueDate: dueDate,
      assignedUserId: assignedUserId,
    );
    if (res['success'] == true) {
      final fetched = await _projectTaskService.getProjectTasks(projectId);
      _tasksByProject[projectId] = fetched;
      _recomputeProjectProgress(projectId);
      notifyListeners();
      // Mirror to user's personal list if it's the current user
      if (assignedUserId == authProvider.currentUser?.id) {
        _firebaseTaskService.createTask(
          title: title,
          description: description,
          priority: TaskPriority.medium,
          dueDate: dueDate,
          tags: const [],
          projectId: projectId,
        );
      }
      return true;
    }
    return false;
  }

  void updateInviteStatus({
    required String projectId,
    required String inviteId,
    required InviteStatus status,
  }) {
    final invites = _invitesByProject[projectId];
    if (invites == null) return;
    final idx = invites.indexWhere((i) => i.id == inviteId);
    if (idx == -1) return;
    final prev = invites[idx];
    invites[idx] = ProjectInvite(
      id: prev.id,
      projectId: prev.projectId,
      email: prev.email,
      invitedBy: prev.invitedBy,
      sentAt: prev.sentAt,
      status: status,
      respondedAt: DateTime.now(),
    );

    if (status == InviteStatus.accepted) {
      // Add as member
      final members = _membersByProject.putIfAbsent(projectId, () => []);
      members.add(
        ProjectMember(
          userId: prev.email, // demo: use email as ID
          name: prev.email.split('@').first,
          email: prev.email,
          role: ProjectRole.member,
          joinedAt: DateTime.now(),
        ),
      );
      // Track in project.teamMembers list
      final pIdx = _projects.indexWhere((p) => p.id == projectId);
      if (pIdx != -1) {
        final p = _projects[pIdx];
        final updated = p.copyWith(
          teamMembers: {...p.teamMembers, prev.email}.toList(),
        );
        _projects[pIdx] = updated;
      }
    }

    notifyListeners();
  }

  Task assignTaskToMember({
    required String projectId,
    required String title,
    required String description,
    DateTime? dueDate,
    required String assignedUserId,
  }) {
    final leaderId = authProvider.currentUser?.id ?? 'leader_demo';
    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      status: TaskStatus.pending,
      priority: TaskPriority.medium,
      createdAt: DateTime.now(),
      dueDate: dueDate,
      assignedTo: assignedUserId,
      assignedBy: leaderId,
      tags: const [],
      projectId: projectId,
    );
    final list = _tasksByProject.putIfAbsent(projectId, () => []);
    list.insert(0, task);
    _recomputeProjectProgress(projectId);
    notifyListeners();

    // Try backend assign
    _projectTaskService
        .assignTask(
          projectId: projectId,
          title: title,
          description: description,
          dueDate: dueDate,
          assignedUserId: assignedUserId,
        )
        .then((res) async {
      if (res['success'] == true) {
        // Refresh from backend list for accuracy
        final fetched = await _projectTaskService.getProjectTasks(projectId);
        _tasksByProject[projectId] = fetched;
        _recomputeProjectProgress(projectId);
        notifyListeners();
      }
    });

    // Mirror to user's personal tasks so it appears on dashboard/calendar
    if (assignedUserId == authProvider.currentUser?.id) {
      _firebaseTaskService.createTask(
        title: title,
        description: description,
        priority: TaskPriority.medium,
        dueDate: dueDate,
        tags: const [],
        projectId: projectId,
      );
    }
    return task;
  }

  // For user: fetch their invites from backend and merge into local for display
  Future<List<ProjectInvite>> fetchMyInvites() async {
    final raw = await _inviteService.getMyInvites();
    final list = raw
        .map((j) => ProjectInvite(
              id: j['_id'] ?? '',
              projectId: (j['project'] is Map) ? j['project']['_id'] : (j['project'] ?? ''),
              email: j['email'] ?? '',
              invitedBy: j['invitedBy'] ?? '',
              sentAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
              status: InviteStatus.values.firstWhere(
                (e) => e.toString().split('.').last == (j['status'] ?? 'pending'),
                orElse: () => InviteStatus.pending,
              ),
              respondedAt: j['respondedAt'] != null
                  ? DateTime.tryParse(j['respondedAt'])
                  : null,
            ))
        .toList();
    _myInvitesCache = list;
    return _myInvitesCache;
  }

  Future<bool> respondToInvite({required String inviteId, required bool accept}) async {
    final ok = await _inviteService.respondToInvite(inviteId: inviteId, accept: accept);
    if (ok) {
      // Refresh my invites cache and projects list where applicable
      await fetchMyInvites();
      // If accepted, project membership should change on backend; lightweight strategy:
      // callers can trigger project reload separately.
    }
    return ok;
  }

  void updateTaskStatus({
    required String projectId,
    required String taskId,
    required TaskStatus status,
  }) {
    final tasks = _tasksByProject[projectId];
    if (tasks == null) return;
    final idx = tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    // Optimistic update
    final prev = tasks[idx];
    tasks[idx] = tasks[idx].copyWith(status: status);
    _recomputeProjectProgress(projectId);
    notifyListeners();

    // Persist to backend then refresh
    _projectTaskService.updateTaskStatus(taskId: taskId, status: status).then((ok) async {
      if (ok) {
        final fetched = await _projectTaskService.getProjectTasks(projectId);
        _tasksByProject[projectId] = fetched;
        _recomputeProjectProgress(projectId);
        notifyListeners();
      } else {
        // rollback on failure
        tasks[idx] = prev;
        _recomputeProjectProgress(projectId);
        notifyListeners();
      }
    });
  }

  List<Task> tasksForUser(String projectId, String userId) {
    return tasks(projectId).where((t) => t.assignedTo == userId).toList();
  }

  void _recomputeProjectProgress(String projectId) {
    final t = _tasksByProject[projectId] ?? const [];
    final total = t.length;
    final done = t.where((x) => x.status == TaskStatus.completed).length;
    final ratio = total == 0 ? 0.0 : done / total;
    final idx = _projects.indexWhere((p) => p.id == projectId);
    if (idx != -1) {
      _projects[idx] = _projects[idx].copyWith(progress: ratio);
    }
  }

  Future<void> _init() async {
    await _loadProjectsFromBackend();
  }

  Future<void> _loadProjectsFromBackend() async {
    _loading = true;
    notifyListeners();
    try {
      final uid = authProvider.currentUser?.id;
      final list = uid != null
          ? await _fsProjectService.getProjectsForUser(uid)
          : <Project>[];
      _projects
        ..clear()
        ..addAll(list);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
