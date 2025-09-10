import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final Function(TaskStatus)? onStatusChanged;
  final VoidCallback? onDelete;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onStatusChanged,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildPriorityChip(task.priority),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                task.description,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (task.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  children: task.tags
                      .take(3)
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatusChip(task.status),
                  const Spacer(),
                  if (task.dueDate != null) ...[
                    Icon(
                      Icons.schedule,
                      size: 12,
                      color: _getDueDateColor(task.dueDate!),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat.MMMd().format(task.dueDate!),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getDueDateColor(task.dueDate!),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (onStatusChanged != null || onDelete != null) ...[
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.grey[600],
                        size: 16,
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 'pending':
                            onStatusChanged?.call(TaskStatus.pending);
                            break;
                          case 'in_progress':
                            onStatusChanged?.call(TaskStatus.inProgress);
                            break;
                          case 'completed':
                            onStatusChanged?.call(TaskStatus.completed);
                            break;
                          case 'cancelled':
                            onStatusChanged?.call(TaskStatus.cancelled);
                            break;
                          case 'delete':
                            onDelete?.call();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        if (onStatusChanged != null) ...[
                          const PopupMenuItem(
                            value: 'pending',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.pending,
                                  color: Colors.blue,
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Text('Mark as Pending'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'in_progress',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.hourglass_empty,
                                  color: Colors.orange,
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Text('Mark as In Progress'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'completed',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Text('Mark as Completed'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'cancelled',
                            child: Row(
                              children: [
                                Icon(Icons.cancel, color: Colors.red, size: 16),
                                SizedBox(width: 8),
                                Text('Mark as Cancelled'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                        ],
                        if (onDelete != null)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 16),
                                SizedBox(width: 8),
                                Text('Delete Task'),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(TaskPriority priority) {
    Color color;
    switch (priority) {
      case TaskPriority.urgent:
        color = Colors.red;
        break;
      case TaskPriority.high:
        color = Colors.orange;
        break;
      case TaskPriority.medium:
        color = Colors.blue;
        break;
      case TaskPriority.low:
        color = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        priority.toString().split('.').last.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusChip(TaskStatus status) {
    Color color;
    IconData icon;
    switch (status) {
      case TaskStatus.completed:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case TaskStatus.inProgress:
        color = Colors.orange;
        icon = Icons.hourglass_empty;
        break;
      case TaskStatus.pending:
        color = Colors.blue;
        icon = Icons.pending;
        break;
      case TaskStatus.cancelled:
        color = Colors.red;
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status.toString().split('.').last.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDueDateColor(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;

    if (difference < 0) {
      return Colors.red; // Overdue
    } else if (difference == 0) {
      return Colors.orange; // Due today
    } else if (difference <= 2) {
      return Colors.amber; // Due soon
    } else {
      return Colors.grey[600]!; // Normal
    }
  }
}
