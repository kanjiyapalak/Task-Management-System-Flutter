import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../services/firebase_task_provider.dart';
import '../../widgets/task_card.dart';
import 'create_task_screen.dart';
import 'task_detail_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final String _searchQuery = '';
  TaskStatus? _selectedStatus;
  TaskPriority? _selectedPriority;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<TaskProvider>(context, listen: false);
      if (provider.tasks.isEmpty && !provider.isLoading) {
        provider.loadTasks();
      }
    });
  }

  List<Task> _filtered(List<Task> allTasks) {
    final result = allTasks.where((task) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!task.title.toLowerCase().contains(q) &&
            !task.description.toLowerCase().contains(q)) {
          return false;
        }
      }
      if (_selectedStatus != null && task.status != _selectedStatus) {
        return false;
      }
      if (_selectedPriority != null && task.priority != _selectedPriority) {
        return false;
      }
      return true;
    }).toList();
    result.sort((a, b) {
      final p = _priorityWeight(
        b.priority,
      ).compareTo(_priorityWeight(a.priority));
      if (p != 0) return p;
      return b.createdAt.compareTo(a.createdAt);
    });
    return result;
  }

  int _priorityWeight(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent:
        return 4;
      case TaskPriority.high:
        return 3;
      case TaskPriority.medium:
        return 2;
      case TaskPriority.low:
        return 1;
    }
  }

  Future<void> _onStatusChanged(Task task, TaskStatus status) async {
    final provider = Provider.of<TaskProvider>(context, listen: false);
    final ok = await provider.updateStatus(task.id, status);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _onDelete(Task task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirm == true) {
      final provider = Provider.of<TaskProvider>(context, listen: false);
      final ok = await provider.deleteTask(task.id);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete task'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        final filteredTasks = _filtered(provider.tasks);
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Tasks',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list, color: Colors.black),
                onPressed: _showFilterBottomSheet,
              ),
              IconButton(
                icon: const Icon(Icons.search, color: Colors.black),
                onPressed: _showSearchDelegate,
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.black),
                onPressed: () => provider.loadTasks(),
              ),
            ],
          ),
          body: Column(
            children: [
              if (_selectedStatus != null || _selectedPriority != null)
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      if (_selectedStatus != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                              _selectedStatus.toString().split('.').last,
                            ),
                            selected: true,
                            onSelected: (_) => setState(() {
                              _selectedStatus = null;
                            }),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () => setState(() {
                              _selectedStatus = null;
                            }),
                          ),
                        ),
                      if (_selectedPriority != null)
                        FilterChip(
                          label: Text(
                            _selectedPriority.toString().split('.').last,
                          ),
                          selected: true,
                          onSelected: (_) => setState(() {
                            _selectedPriority = null;
                          }),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => setState(() {
                            _selectedPriority = null;
                          }),
                        ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedStatus = null;
                            _selectedPriority = null;
                          });
                        },
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredTasks.isEmpty
                    ? _buildEmptyState(provider.tasks)
                    : RefreshIndicator(
                        onRefresh: () => provider.loadTasks(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredTasks.length,
                          itemBuilder: (context, i) {
                            final task = filteredTasks[i];
                            return TaskCard(
                              task: task,
                              onTap: () => _navigateToTaskDetail(task),
                              onStatusChanged: (s) => _onStatusChanged(task, s),
                              onDelete: () => _onDelete(task),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _navigateToCreateTask,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(List<Task> all) {
    final empty = all.isEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            empty ? Icons.assignment : Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            empty ? 'No Tasks Yet' : 'No Matching Tasks',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            empty
                ? 'Create your first task to get started!'
                : 'Try adjusting your filters or search terms',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          if (empty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToCreateTask,
              icon: const Icon(Icons.add),
              label: const Text('Create Task'),
            ),
          ],
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Tasks',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedStatus == null,
                    onSelected: (_) =>
                        setModalState(() => _selectedStatus = null),
                  ),
                  ...TaskStatus.values.map(
                    (s) => FilterChip(
                      label: Text(s.toString().split('.').last),
                      selected: _selectedStatus == s,
                      onSelected: (sel) =>
                          setModalState(() => _selectedStatus = sel ? s : null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Priority',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedPriority == null,
                    onSelected: (_) =>
                        setModalState(() => _selectedPriority = null),
                  ),
                  ...TaskPriority.values.map(
                    (p) => FilterChip(
                      label: Text(p.toString().split('.').last),
                      selected: _selectedPriority == p,
                      onSelected: (sel) => setModalState(
                        () => _selectedPriority = sel ? p : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {});
                  },
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchDelegate() {
    final provider = Provider.of<TaskProvider>(context, listen: false);
    showSearch(
      context: context,
      delegate: TaskSearchDelegate(
        tasks: provider.tasks,
        onTaskSelected: _navigateToTaskDetail,
      ),
    );
  }

  Future<void> _navigateToCreateTask() async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CreateTaskScreen()));
    // No reload needed; provider already inserted the task & notified.
    if (result == true && mounted) setState(() {});
  }

  Future<void> _navigateToTaskDetail(Task task) async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)));
    if (result != null && mounted) {
      Provider.of<TaskProvider>(context, listen: false).loadTasks();
    }
  }
}

class TaskSearchDelegate extends SearchDelegate<Task?> {
  final List<Task> tasks;
  final Function(Task) onTaskSelected;
  TaskSearchDelegate({required this.tasks, required this.onTaskSelected});
  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];
  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );
  @override
  Widget buildResults(BuildContext context) => buildSuggestions(context);
  @override
  Widget buildSuggestions(BuildContext context) {
    final filtered = tasks.where((t) {
      final q = query.toLowerCase();
      return t.title.toLowerCase().contains(q) ||
          t.description.toLowerCase().contains(q) ||
          t.tags.any((tag) => tag.toLowerCase().contains(q));
    }).toList();
    if (filtered.isEmpty) return const Center(child: Text('No tasks found'));
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (c, i) {
        final task = filtered[i];
        return ListTile(
          title: Text(task.title),
          subtitle: Text(
            task.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _statusIcon(task.status),
                color: _statusColor(task.status),
                size: 16,
              ),
              Text(
                task.priority.toString().split('.').last,
                style: TextStyle(
                  fontSize: 10,
                  color: _priorityColor(task.priority),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          onTap: () {
            close(c, task);
            onTaskSelected(task);
          },
        );
      },
    );
  }

  IconData _statusIcon(TaskStatus s) {
    switch (s) {
      case TaskStatus.pending:
        return Icons.pending;
      case TaskStatus.inProgress:
        return Icons.hourglass_empty;
      case TaskStatus.completed:
        return Icons.check_circle;
      case TaskStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _statusColor(TaskStatus s) {
    switch (s) {
      case TaskStatus.pending:
        return Colors.blue;
      case TaskStatus.inProgress:
        return Colors.orange;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.cancelled:
        return Colors.red;
    }
  }

  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.urgent:
        return Colors.red;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.medium:
        return Colors.blue;
      case TaskPriority.low:
        return Colors.green;
    }
  }
}
