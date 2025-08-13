import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';
import '../../widgets/task_card.dart';
import 'create_task_screen.dart';
import 'task_detail_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TaskService _taskService = TaskService();
  List<Task> _allTasks = [];
  List<Task> _filteredTasks = [];
  bool _isLoading = true;
  String _searchQuery = '';
  TaskStatus? _selectedStatus;
  TaskPriority? _selectedPriority;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await _taskService.getTasks();
      setState(() {
        _allTasks = tasks;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading tasks: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredTasks = _allTasks.where((task) {
        // Search filter
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          if (!task.title.toLowerCase().contains(query) &&
              !task.description.toLowerCase().contains(query)) {
            return false;
          }
        }

        // Status filter
        if (_selectedStatus != null && task.status != _selectedStatus) {
          return false;
        }

        // Priority filter
        if (_selectedPriority != null && task.priority != _selectedPriority) {
          return false;
        }

        return true;
      }).toList();

      // Sort by priority and then by creation date
      _filteredTasks.sort((a, b) {
        final priorityComparison = _getPriorityWeight(
          b.priority,
        ).compareTo(_getPriorityWeight(a.priority));
        if (priorityComparison != 0) return priorityComparison;
        return b.createdAt.compareTo(a.createdAt);
      });
    });
  }

  int _getPriorityWeight(TaskPriority priority) {
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

  Future<void> _updateTaskStatus(Task task, TaskStatus newStatus) async {
    final result = await _taskService.updateTaskStatus(task.id, newStatus);

    if (result['success']) {
      _loadTasks(); // Reload to get updated data
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task ${newStatus.toString().split('.').last}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _taskService.deleteTask(task.id);
      if (result['success']) {
        _loadTasks();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Tasks',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
        ],
      ),
      body: Column(
        children: [
          // Filter chips
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
                        label: Text(_selectedStatus.toString().split('.').last),
                        selected: true,
                        onSelected: (bool selected) {
                          setState(() {
                            _selectedStatus = null;
                            _applyFilters();
                          });
                        },
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            _selectedStatus = null;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                  if (_selectedPriority != null)
                    FilterChip(
                      label: Text(_selectedPriority.toString().split('.').last),
                      selected: true,
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedPriority = null;
                          _applyFilters();
                        });
                      },
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _selectedPriority = null;
                          _applyFilters();
                        });
                      },
                    ),
                  const Spacer(),
                  if (_selectedStatus != null || _selectedPriority != null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedStatus = null;
                          _selectedPriority = null;
                          _applyFilters();
                        });
                      },
                      child: const Text('Clear All'),
                    ),
                ],
              ),
            ),

          // Task list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTasks.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadTasks,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = _filteredTasks[index];
                        return TaskCard(
                          task: task,
                          onTap: () => _navigateToTaskDetail(task),
                          onStatusChanged: (newStatus) =>
                              _updateTaskStatus(task, newStatus),
                          onDelete: () => _deleteTask(task),
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
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _allTasks.isEmpty ? Icons.assignment : Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _allTasks.isEmpty ? 'No Tasks Yet' : 'No Matching Tasks',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _allTasks.isEmpty
                ? 'Create your first task to get started!'
                : 'Try adjusting your filters or search terms',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          if (_allTasks.isEmpty) ...[
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

              // Status filter
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
                    onSelected: (selected) {
                      setModalState(() => _selectedStatus = null);
                    },
                  ),
                  ...TaskStatus.values.map(
                    (status) => FilterChip(
                      label: Text(status.toString().split('.').last),
                      selected: _selectedStatus == status,
                      onSelected: (selected) {
                        setModalState(
                          () => _selectedStatus = selected ? status : null,
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Priority filter
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
                    onSelected: (selected) {
                      setModalState(() => _selectedPriority = null);
                    },
                  ),
                  ...TaskPriority.values.map(
                    (priority) => FilterChip(
                      label: Text(priority.toString().split('.').last),
                      selected: _selectedPriority == priority,
                      onSelected: (selected) {
                        setModalState(
                          () => _selectedPriority = selected ? priority : null,
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Apply button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _applyFilters();
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
    showSearch(
      context: context,
      delegate: TaskSearchDelegate(
        tasks: _allTasks,
        onTaskSelected: _navigateToTaskDetail,
      ),
    );
  }

  Future<void> _navigateToCreateTask() async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const CreateTaskScreen()));

    if (result == true) {
      _loadTasks(); // Refresh the list if a task was created
    }
  }

  Future<void> _navigateToTaskDetail(Task task) async {
    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(builder: (context) => TaskDetailScreen(task: task)),
    );
    
    // If task was updated or deleted, refresh the task list
    if (result != null) {
      _loadTasks();
    }
  }
}

class TaskSearchDelegate extends SearchDelegate<Task?> {
  final List<Task> tasks;
  final Function(Task) onTaskSelected;

  TaskSearchDelegate({required this.tasks, required this.onTaskSelected});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final filteredTasks = tasks.where((task) {
      final queryLower = query.toLowerCase();
      return task.title.toLowerCase().contains(queryLower) ||
          task.description.toLowerCase().contains(queryLower) ||
          task.tags.any((tag) => tag.toLowerCase().contains(queryLower));
    }).toList();

    if (filteredTasks.isEmpty) {
      return const Center(child: Text('No tasks found'));
    }

    return ListView.builder(
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        final task = filteredTasks[index];
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
                _getStatusIcon(task.status),
                color: _getStatusColor(task.status),
                size: 16,
              ),
              Text(
                task.priority.toString().split('.').last,
                style: TextStyle(
                  fontSize: 10,
                  color: _getPriorityColor(task.priority),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          onTap: () {
            close(context, task);
            onTaskSelected(task);
          },
        );
      },
    );
  }

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
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

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
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

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
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
