import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/project_provider.dart';
import 'project_dashboard_screen.dart';

class ArchivedProjectsScreen extends StatelessWidget {
  const ArchivedProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<ProjectProvider>(context);
    final archived = prov.projects.where((p) => p.archived).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Archived Projects',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: archived.isEmpty
          ? Center(
              child: Text('No archived projects', style: TextStyle(color: Colors.grey[600])),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: archived.length,
              itemBuilder: (c, i) {
                final p = archived[i];
                return Card(
                  child: ListTile(
                    title: Text(p.name),
                    subtitle: Text(p.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        switch (v) {
                          case 'open':
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProjectDashboardScreen(project: p),
                              ),
                            );
                            break;
                          case 'unarchive':
                            Provider.of<ProjectProvider>(context, listen: false)
                                .setProjectArchived(p.id, false);
                            break;
                        }
                      },
                      itemBuilder: (c) => const [
                        PopupMenuItem(value: 'open', child: Text('Open')),
                        PopupMenuItem(value: 'unarchive', child: Text('Unarchive')),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
