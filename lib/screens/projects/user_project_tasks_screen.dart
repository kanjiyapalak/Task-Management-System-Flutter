import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/project.dart';
import '../../models/task.dart';
import '../../services/firebase_auth_provider.dart';
import '../../services/project_provider.dart';
import '../../widgets/task_card.dart';

class UserProjectTasksScreen extends StatelessWidget {
  final Project project;
  const UserProjectTasksScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final userId = auth.currentUser?.id ?? '';
    final prov = Provider.of<ProjectProvider>(context);
    final myTasks = prov.tasksForUser(project.id, userId);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Project Tasks',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: myTasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_available, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'No tasks assigned yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: myTasks.length,
              itemBuilder: (c, i) {
                final t = myTasks[i];
                return Dismissible(
                  key: ValueKey(t.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: Colors.green,
                    child: const Icon(Icons.check, color: Colors.white),
                  ),
                  confirmDismiss: (dir) async {
                    Provider.of<ProjectProvider>(c, listen: false)
                        .updateTaskStatus(
                      projectId: project.id,
                      taskId: t.id,
                      status: TaskStatus.completed,
                    );
                    return false; // keep the tile; UI will update
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: TaskCard(task: t, onTap: null),
                  ),
                );
              },
            ),
    );
  }
}
