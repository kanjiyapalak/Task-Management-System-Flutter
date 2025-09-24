import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/project.dart';
import '../../models/project_member.dart';
import '../../services/project_provider.dart';
import '../../widgets/task_card.dart';

class MemberProjectTasksScreen extends StatelessWidget {
  final Project project;
  final ProjectMember member;
  const MemberProjectTasksScreen({super.key, required this.project, required this.member});

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<ProjectProvider>(context);
    prov.ensureProjectTasksLoaded(project.id);
    final tasks = prov.tasksForUser(project.id, member.userId);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '${member.name}\'s Tasks',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_available, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'No tasks assigned to ${member.name}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              itemBuilder: (c, i) {
                final t = tasks[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: TaskCard(task: t, onTap: null),
                );
              },
            ),
    );
  }
}
