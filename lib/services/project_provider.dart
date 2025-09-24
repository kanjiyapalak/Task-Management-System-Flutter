import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project.dart';
import '../models/project_member.dart';
import '../models/project_invite.dart';
import '../models/task.dart';
import 'firebase_task_service.dart';
import 'firebase_auth_provider.dart';
import 'project_task_service.dart';
import 'firestore_project_service.dart';
import 'firestore_invite_service.dart';
import 'firestore_project_task_service.dart';

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
  final Set<String> _membersFetched = {};
  bool _loading = false;
  final FirebaseTaskService _firebaseTaskService = FirebaseTaskService();
  final ProjectTaskService _projectTaskService = ProjectTaskService();
  // final InviteService _inviteService = InviteService(); // legacy REST (unused)
  final FirestoreInviteService _fsInviteService = FirestoreInviteService();
  // Switch to Firestore for project persistence
  final FirestoreProjectService _fsProjectService = FirestoreProjectService();
  final FirestoreProjectTaskService _fsTaskService = FirestoreProjectTaskService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
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

  Future<bool> updateProject({
    required String projectId,
    required String name,
    required String description,
    DateTime? dueDate,
    ProjectStatus? status,
  }) async {
    final ok = await _fsProjectService.updateProject(
      projectId: projectId,
      name: name,
      description: description,
      dueDate: dueDate,
      status: status,
    );
    if (ok) {
      final i = _projects.indexWhere((p) => p.id == projectId);
      if (i != -1) {
        _projects[i] = _projects[i].copyWith(
          name: name,
          description: description,
          dueDate: dueDate,
          status: status ?? _projects[i].status,
        );
      }
      notifyListeners();
    }
    return ok;
  }

  Future<bool> setProjectArchived(String projectId, bool archived) async {
    final ok = await _fsProjectService.setArchived(projectId, archived);
    if (ok) {
      final i = _projects.indexWhere((p) => p.id == projectId);
      if (i != -1) {
        _projects[i] = _projects[i].copyWith(archived: archived);
      }
      notifyListeners();
    }
    return ok;
  }

  void sendInvites({
    required String projectId,
    required List<String> emails,
  }) {
    // Optimistic local add
    final list = _invitesByProject.putIfAbsent(projectId, () => []);
    final inviterUid = authProvider.currentUser?.id;
    final inviterLocal = inviterUid ?? 'leader_demo';
    final now = DateTime.now();
    for (final email in emails.where((e) => e.trim().isNotEmpty)) {
      // Skip duplicate pending invites locally
      final already = list.any((i) =>
          i.email.toLowerCase() == email.trim().toLowerCase() &&
          i.status == InviteStatus.pending);
      if (already) continue;
      list.add(ProjectInvite(
        id: 'tmp-${now.microsecondsSinceEpoch}-${email.hashCode}',
        projectId: projectId,
        email: email.trim(),
        invitedBy: inviterLocal,
        sentAt: now,
        status: InviteStatus.pending,
      ));
    }
    notifyListeners();
    // Persist to Firestore
    if (inviterUid != null) {
      _fsInviteService.sendInvites(
        projectId: projectId,
        emails: emails,
        invitedByUid: inviterUid,
      );
    }
  }

  Future<void> refreshInvitesForProject(String projectId) async {
    try {
      final raw = await _fsInviteService.getProjectInvites(projectId);
      final list = raw
          .map((j) => ProjectInvite(
                id: j['id'] ?? '',
                projectId: j['projectId'] ?? projectId,
                email: j['email'] ?? '',
                invitedBy: j['invitedBy'] ?? '',
                sentAt: (j['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                status: InviteStatus.values.firstWhere(
                  (e) => e.toString().split('.').last == (j['status'] ?? 'pending'),
                  orElse: () => InviteStatus.pending,
                ),
                respondedAt: (j['respondedAt'] as Timestamp?)?.toDate(),
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
    // Load from Firestore tasks subcollection
    final fetched = await _fsTaskService.getProjectTasks(projectId);
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
    final leaderId = authProvider.currentUser?.id;
    if (leaderId == null) return false;
    final ok = await _fsTaskService.assignTask(
      projectId: projectId,
      title: title,
      description: description,
      assignedUserId: assignedUserId,
      dueDate: dueDate,
      assignedBy: leaderId,
    );
    if (!ok) return false;
    final fetched = await _fsTaskService.getProjectTasks(projectId);
    _tasksByProject[projectId] = fetched;
    _recomputeProjectProgress(projectId);
    notifyListeners();
    // Mirror to personal tasks if assigned to self
    if (assignedUserId == leaderId) {
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
    final email = authProvider.currentUser?.email;
    if (email == null || email.isEmpty) return [];
    final raw = await _fsInviteService.getMyInvites(email);
    final list = raw
        .map((j) => ProjectInvite(
              id: j['id'] ?? '',
              projectId: j['projectId'] ?? '',
              email: j['email'] ?? '',
              invitedBy: j['invitedBy'] ?? '',
              sentAt: (j['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              status: InviteStatus.values.firstWhere(
                (e) => e.toString().split('.').last == (j['status'] ?? 'pending'),
                orElse: () => InviteStatus.pending,
              ),
              respondedAt: (j['respondedAt'] as Timestamp?)?.toDate(),
            ))
        .toList();
    _myInvitesCache = list;
    return _myInvitesCache;
  }

  Future<bool> respondToInvite({required String inviteId, required bool accept}) async {
    final uid = authProvider.currentUser?.id;
    if (uid == null) return false;
    final ok = await _fsInviteService.respondToInvite(inviteId: inviteId, accept: accept, userId: uid);
    if (ok) {
      // Refresh my invites cache and projects list where applicable
      await fetchMyInvites();
      // If accepted, project membership should change on backend; lightweight strategy:
      // callers can trigger project reload separately.
    }
    return ok;
  }

  // Sent invites by current leader/user
  Future<List<ProjectInvite>> fetchSentInvitesBy(String inviterUid) async {
    final raw = await _fsInviteService.getSentInvitesBy(inviterUid);
    return raw
        .map((j) => ProjectInvite(
              id: j['id'] ?? '',
              projectId: j['projectId'] ?? '',
              email: j['email'] ?? '',
              invitedBy: j['invitedBy'] ?? '',
              sentAt: (j['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              status: InviteStatus.values.firstWhere(
                (e) => e.toString().split('.').last == (j['status'] ?? 'pending'),
                orElse: () => InviteStatus.pending,
              ),
              respondedAt: (j['respondedAt'] as Timestamp?)?.toDate(),
            ))
        .toList();
  }

  // Delete invite (only pending). Returns true if deleted.
  Future<bool> deleteInvite(String inviteId) async {
    final ok = await _fsInviteService.deleteInvite(inviteId);
    if (ok) {
      // Remove from local caches too
      _invitesByProject.updateAll((key, list) {
        return list.where((i) => i.id != inviteId).toList();
      });
      _myInvitesCache = _myInvitesCache.where((i) => i.id != inviteId).toList();
      notifyListeners();
    }
    return ok;
  }

  // Real-time streams
  Stream<List<ProjectInvite>> myInvitesStream(String email) {
    return _fsInviteService.myInvitesStream(email).map((raw) {
      final list = raw
          .map((j) => ProjectInvite(
              id: j['id'] ?? '',
              projectId: j['projectId'] ?? '',
              email: j['email'] ?? '',
              invitedBy: j['invitedBy'] ?? '',
              sentAt: (j['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              status: InviteStatus.values.firstWhere(
                (e) => e.toString().split('.').last == (j['status'] ?? 'pending'),
                orElse: () => InviteStatus.pending,
              ),
              respondedAt: (j['respondedAt'] as Timestamp?)?.toDate(),
            ))
          .toList();
      list.sort((a, b) => b.sentAt.compareTo(a.sentAt));
      return list;
    });
  }

  Stream<List<ProjectInvite>> sentInvitesStream(String inviterUid) {
    return _fsInviteService.sentInvitesStream(inviterUid).map((raw) {
      final list = raw
          .map((j) => ProjectInvite(
              id: j['id'] ?? '',
              projectId: j['projectId'] ?? '',
              email: j['email'] ?? '',
              invitedBy: j['invitedBy'] ?? '',
              sentAt: (j['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              status: InviteStatus.values.firstWhere(
                (e) => e.toString().split('.').last == (j['status'] ?? 'pending'),
                orElse: () => InviteStatus.pending,
              ),
              respondedAt: (j['respondedAt'] as Timestamp?)?.toDate(),
            ))
          .toList();
      list.sort((a, b) => b.sentAt.compareTo(a.sentAt));
      return list;
    });
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

    // Persist to Firestore then refresh
    _fsTaskService
        .updateTaskStatus(projectId: projectId, taskId: taskId, status: status)
        .then((ok) async {
      if (ok) {
        final fetched = await _fsTaskService.getProjectTasks(projectId);
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
      // For each project, ensure leader and basic member list
      for (final p in _projects) {
        await _hydrateMembersForProject(p);
        _membersFetched.add(p.id);
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _hydrateMembersForProject(Project p) async {
    // Map teamMembers (userIds) into ProjectMember using users collection
    final usersCol = _db.collection('users');
    final members = <ProjectMember>[];
    for (final uid in p.teamMembers) {
      try {
        final doc = await usersCol.doc(uid).get();
  final data = doc.data();
    final fullNameDyn = data?['fullName'];
    final fullNameField = fullNameDyn is String ? fullNameDyn.trim() : null;
    final firstDyn = data?['firstName'];
    final lastDyn = data?['lastName'];
    final first = firstDyn is String ? firstDyn.trim() : '';
    final last = lastDyn is String ? lastDyn.trim() : '';
        final composed = ('$first $last').trim();
        final name = (fullNameField != null && fullNameField.isNotEmpty)
            ? fullNameField
            : composed;
    final emailDyn = data?['email'];
    final email = emailDyn is String ? emailDyn : '';
        members.add(ProjectMember(
          userId: uid,
          name: name.isNotEmpty ? name : (email.isNotEmpty ? email.split('@').first : uid),
          email: email,
          role: uid == p.createdBy ? ProjectRole.leader : ProjectRole.member,
          joinedAt: DateTime.now(),
        ));
      } catch (_) {
        members.add(ProjectMember(
          userId: uid,
          name: uid,
          email: '',
          role: uid == p.createdBy ? ProjectRole.leader : ProjectRole.member,
          joinedAt: DateTime.now(),
        ));
      }
    }
    _membersByProject[p.id] = members;
  }

  Future<void> ensureMembersLoaded(String projectId) async {
    if (_membersFetched.contains(projectId) && (_membersByProject[projectId]?.isNotEmpty ?? false)) {
      return;
    }
    await refreshMembersForProject(projectId);
  }

  Future<void> refreshMembersForProject(String projectId) async {
    try {
      final doc = await _db.collection('projects').doc(projectId).get();
      if (!doc.exists) return;
  final j = doc.data() ?? {};
      final p = Project(
        id: doc.id,
        name: j['name'] ?? '',
        description: j['description'] ?? '',
        status: ProjectStatus.values.firstWhere(
          (e) => e.toString().split('.').last == (j['status'] ?? 'planning'),
          orElse: () => ProjectStatus.planning,
        ),
        createdAt: (j['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        dueDate: (j['dueDate'] as Timestamp?)?.toDate(),
        teamMembers: List<String>.from(j['teamMembers'] ?? const []),
        progress: (j['progress'] ?? 0.0).toDouble(),
        createdBy: j['createdBy'] ?? '',
      );
      // update project in local list
      final idx = _projects.indexWhere((x) => x.id == projectId);
      if (idx != -1) _projects[idx] = p;
      await _hydrateMembersForProject(p);
      _membersFetched.add(projectId);
      notifyListeners();
    } catch (_) {}
  }
}
