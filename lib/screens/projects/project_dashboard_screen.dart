import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/project.dart';
import '../../models/task.dart';
import '../../services/project_provider.dart';
import '../../widgets/task_card.dart';
import 'assign_task_screen.dart';
import 'project_members_screen.dart';
import 'invite_users_screen.dart';
import 'user_project_tasks_screen.dart';

class ProjectDashboardScreen extends StatelessWidget {
  final Project project;
  const ProjectDashboardScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<ProjectProvider>(context);
    // Ensure tasks are loaded from backend when opening
    prov.ensureProjectTasksLoaded(project.id);
    final tasks = prov.tasks(project.id);
    final members = prov.members(project.id);
    final completed =
        tasks.where((t) => t.status == TaskStatus.completed).length;
    final progress = tasks.isEmpty ? 0.0 : completed / tasks.length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          project.name,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.black),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => InviteUsersScreen(project: project),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.group, color: Colors.black),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProjectMembersScreen(project: project),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.black),
            tooltip: 'My Tasks',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => UserProjectTasksScreen(project: project),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AssignTaskScreen(project: project),
          ),
        ),
        icon: const Icon(Icons.add_task),
        label: const Text('Assign Task'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(project),
            const SizedBox(height: 16),
            _progress(progress),
            const SizedBox(height: 16),
            _meta(project, members.length, tasks.length),
            const SizedBox(height: 16),
            _tasksSection(context, tasks),
          ],
        ),
      ),
    );
  }

  Widget _header(Project project) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project.description,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            if (project.dueDate != null)
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16),
                  const SizedBox(width: 6),
                  Text('Due ${DateFormat.yMMMd().format(project.dueDate!)}'),
                ],
              ),
          ],
        ),
      );

  Widget _progress(double value) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Project Progress',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text('${(value * 100).toInt()}%'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                value >= 0.8
                    ? Colors.green
                    : value >= 0.5
                        ? Colors.blue
                        : value >= 0.2
                            ? Colors.orange
                            : Colors.red,
              ),
            ),
          ],
        ),
      );

  Widget _meta(Project project, int members, int tasks) => Row(
        children: [
          Expanded(
            child: _metaCard(
              title: 'Members',
              value: members.toString(),
              color: Colors.indigo,
              icon: Icons.group,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _metaCard(
              title: 'Tasks',
              value: tasks.toString(),
              color: Colors.blue,
              icon: Icons.task,
            ),
          ),
        ],
      );

  Widget _metaCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(title, style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ],
        ),
      );

  Widget _tasksSection(BuildContext context, List<Task> tasks) {
    if (tasks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No tasks yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final sorted = [...tasks]..sort(
        (a, b) => (a.status == TaskStatus.completed ? 1 : 0)
            .compareTo(b.status == TaskStatus.completed ? 1 : 0),
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Project Tasks',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...sorted.map(
          (t) {
      final prov = Provider.of<ProjectProvider>(context, listen: false);
      final memberList = prov
        .members(project.id)
        .where((m) => m.userId == t.assignedTo)
        .toList();
      final assignedLabel = memberList.isNotEmpty
        ? memberList.first.name
                : (t.assignedTo == prov.authProvider.currentUser?.id
                    ? 'You'
                    : t.assignedTo);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TaskCard(task: t, onTap: null),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Assigned to: $assignedLabel',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
