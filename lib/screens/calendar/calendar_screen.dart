import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../services/firebase_task_provider.dart';
import '../../widgets/task_card.dart';
import '../tasks/task_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();
  static const String _layoutVersion = 'v2-responsive';

  @override
  void initState() {
    super.initState();
  }

  List<Task> _tasksForDate(List<Task> all, DateTime date) => all
      .where((t) => t.dueDate != null && DateUtils.isSameDay(t.dueDate!, date))
      .toList();

  bool _hasTasksOnDate(List<Task> all, DateTime date) =>
      _tasksForDate(all, date).isNotEmpty;

  void _onDateSelected(DateTime d) {
    setState(() {
      _selectedDate = d;
    });
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  void _goToToday() {
    final today = DateTime.now();
    setState(() {
      _currentMonth = today;
      _selectedDate = today;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Debug marker so you can verify the updated file is active.
    // ignore: avoid_print
    print('CalendarScreen build -> layout: $_layoutVersion');

    // Use a simple widget without Provider to test basic functionality
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        final all = provider.tasks;
        final tasksForSelected = _tasksForDate(all, _selectedDate);
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Calendar',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              TextButton(onPressed: _goToToday, child: const Text('Today')),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.black),
                onPressed: () => provider.loadTasks(),
              ),
            ],
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildHeaderBar(),
                    Container(
                      color: Colors.white,
                      height: 320,
                      child: _buildCalendarGrid(all),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: _buildTasksList(tasksForSelected),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildHeaderBar() => Container(
    color: Colors.white,
    padding: const EdgeInsets.all(16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: _previousMonth,
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          DateFormat.yMMMM().format(_currentMonth),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          onPressed: _nextMonth,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    ),
  );

  Widget _buildCalendarGrid(List<Task> all) {
    final first = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final last = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final start = first.subtract(Duration(days: first.weekday - 1));
    final end = last.add(Duration(days: 7 - last.weekday));

    final days = <DateTime>[];
    for (
      var d = start;
      d.isBefore(end) || d.isAtSameMomentAs(end);
      d = d.add(const Duration(days: 1))
    ) {
      days.add(d);
    }

    return Column(
      children: [
        // Weekday headers
        SizedBox(
          height: 40,
          child: Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map(
                  (wd) => Expanded(
                    child: Center(
                      child: Text(
                        wd,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),

        // Calendar days
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: days.length,
            itemBuilder: (c, i) {
              final day = days[i];
              final isCurrent = day.month == _currentMonth.month;
              final isSelected = DateUtils.isSameDay(day, _selectedDate);
              final isToday = DateUtils.isSameDay(day, DateTime.now());
              final has = _hasTasksOnDate(all, day);

              return GestureDetector(
                onTap: () => _onDateSelected(day),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(c).primaryColor
                        : isToday
                        ? Theme.of(c).primaryColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday && !isSelected
                        ? Border.all(color: Theme.of(c).primaryColor)
                        : null,
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          day.day.toString(),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : isCurrent
                                ? Colors.black
                                : Colors.grey,
                            fontWeight: isToday
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (has)
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(c).primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTasksList(List<Task> tasksForSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat.yMMMEd().format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  '${tasksForSelected.length} task${tasksForSelected.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: tasksForSelected.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_available,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tasks for this date',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: tasksForSelected.length,
                  itemBuilder: (c, i) {
                    final task = tasksForSelected[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: TaskCard(
                        task: task,
                        onTap: () {
                          Navigator.of(c).push(
                            MaterialPageRoute(
                              builder: (_) => TaskDetailScreen(task: task),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
