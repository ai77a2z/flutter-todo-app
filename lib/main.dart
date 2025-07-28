import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Todo App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TodoHomePage(),
    );
  }
}

// Filter enum for task filtering
enum TaskFilter { all, active, completed }

// Task category enum
enum TaskCategory { 
  personal, 
  work, 
  shopping, 
  health, 
  finance,
  other 
}

// Extension to get category properties
extension TaskCategoryExtension on TaskCategory {
  String get displayName {
    switch (this) {
      case TaskCategory.personal:
        return 'Personal';
      case TaskCategory.work:
        return 'Work';
      case TaskCategory.shopping:
        return 'Shopping';
      case TaskCategory.health:
        return 'Health';
      case TaskCategory.finance:
        return 'Finance';
      case TaskCategory.other:
        return 'Other';
    }
  }

  Color get color {
    switch (this) {
      case TaskCategory.personal:
        return Colors.blue;
      case TaskCategory.work:
        return Colors.orange;
      case TaskCategory.shopping:
        return Colors.green;
      case TaskCategory.health:
        return Colors.red;
      case TaskCategory.finance:
        return Colors.purple;
      case TaskCategory.other:
        return Colors.grey;
    }
  }

  IconData get icon {
    switch (this) {
      case TaskCategory.personal:
        return Icons.person;
      case TaskCategory.work:
        return Icons.work;
      case TaskCategory.shopping:
        return Icons.shopping_cart;
      case TaskCategory.health:
        return Icons.favorite;
      case TaskCategory.finance:
        return Icons.attach_money;
      case TaskCategory.other:
        return Icons.label;
    }
  }
}

// Task model
class Task {
  String title;
  bool isCompleted;
  TaskCategory category;
  
  Task({
    required this.title, 
    this.isCompleted = false,
    this.category = TaskCategory.personal,
  });

  // Convert Task to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'isCompleted': isCompleted,
      'category': category.name,
    };
  }

  // Create Task from JSON
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      title: json['title'],
      isCompleted: json['isCompleted'],
      category: TaskCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => TaskCategory.personal,
      ),
    );
  }
}

class TodoHomePage extends StatefulWidget {
  const TodoHomePage({super.key});

  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _editController = TextEditingController();
  final FocusNode _taskFocusNode = FocusNode();
  final List<Task> _tasks = [];
  TaskFilter _currentFilter = TaskFilter.all;
  TaskCategory _selectedCategory = TaskCategory.personal;
  int? _editingTaskIndex; // Track which task is being edited

  @override
  void initState() {
    super.initState();
    _loadTasks();
    // Ensure focus after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _taskFocusNode.requestFocus();
    });
  }

  // Get filtered tasks based on current filter
  List<Task> get _filteredTasks {
    switch (_currentFilter) {
      case TaskFilter.active:
        return _tasks.where((task) => !task.isCompleted).toList();
      case TaskFilter.completed:
        return _tasks.where((task) => task.isCompleted).toList();
      case TaskFilter.all:
      default:
        return _tasks;
    }
  }

  // Load tasks from SharedPreferences
  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getString('tasks');
    if (tasksJson != null) {
      final List<dynamic> tasksList = json.decode(tasksJson);
      setState(() {
        _tasks.clear();
        _tasks.addAll(tasksList.map((json) => Task.fromJson(json)).toList());
      });
    }
  }

  // Save tasks to SharedPreferences
  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = json.encode(_tasks.map((task) => task.toJson()).toList());
    await prefs.setString('tasks', tasksJson);
  }

  void _addTask() {
    if (_taskController.text.trim().isNotEmpty) {
      setState(() {
        _tasks.add(Task(title: _taskController.text.trim(), category: _selectedCategory));
        _taskController.clear();
      });
      _saveTasks();
      // Refocus the input field after adding a task
      _taskFocusNode.requestFocus();
    }
  }

  void _toggleTask(int index) {
    // Find the actual task in the main list
    final task = _filteredTasks[index];
    final mainIndex = _tasks.indexOf(task);
    
    setState(() {
      _tasks[mainIndex].isCompleted = !_tasks[mainIndex].isCompleted;
    });
    _saveTasks();
  }

  void _deleteTask(int index) {
    // Find the actual task in the main list
    final task = _filteredTasks[index];
    final mainIndex = _tasks.indexOf(task);
    
    setState(() {
      _tasks.removeAt(mainIndex);
    });
    _saveTasks();
  }

  void _setFilter(TaskFilter filter) {
    setState(() {
      _currentFilter = filter;
    });
  }

  void _startEditingTask(int index) {
    final task = _filteredTasks[index];
    setState(() {
      _editingTaskIndex = index;
      _editController.text = task.title;
    });
  }

  void _saveEditedTask() {
    if (_editingTaskIndex != null && _editController.text.trim().isNotEmpty) {
      final task = _filteredTasks[_editingTaskIndex!];
      final mainIndex = _tasks.indexOf(task);
      
      setState(() {
        _tasks[mainIndex].title = _editController.text.trim();
        _editingTaskIndex = null;
        _editController.clear();
      });
      _saveTasks();
    } else {
      _cancelEditing();
    }
  }

  void _cancelEditing() {
    setState(() {
      _editingTaskIndex = null;
      _editController.clear();
    });
  }

  String _getFilterDisplayName(TaskFilter filter) {
    switch (filter) {
      case TaskFilter.all:
        return 'All';
      case TaskFilter.active:
        return 'Active';
      case TaskFilter.completed:
        return 'Completed';
    }
  }

  int get _remainingTasks => _tasks.where((task) => !task.isCompleted).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Todo List',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          // Input Section
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Task Input Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _taskController,
                        focusNode: _taskFocusNode,
                        decoration: const InputDecoration(
                          hintText: 'Add a new task...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        onSubmitted: (_) => _addTask(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Category Selection Row
                Row(
                  children: [
                    const Text(
                      'Category:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _selectedCategory.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _selectedCategory.color.withOpacity(0.3),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<TaskCategory>(
                            value: _selectedCategory,
                            isExpanded: true,
                            icon: Icon(Icons.arrow_drop_down, color: _selectedCategory.color),
                            style: TextStyle(color: _selectedCategory.color, fontSize: 14),
                            onChanged: (TaskCategory? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedCategory = newValue;
                                });
                              }
                            },
                            items: TaskCategory.values.map<DropdownMenuItem<TaskCategory>>((TaskCategory category) {
                              return DropdownMenuItem<TaskCategory>(
                                value: category,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      category.icon,
                                      size: 16,
                                      color: category.color,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(category.displayName),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Task List Section
          Expanded(
            child: _filteredTasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _currentFilter == TaskFilter.completed 
                              ? Icons.task_alt 
                              : Icons.check_circle_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _currentFilter == TaskFilter.completed 
                              ? 'No completed tasks!'
                              : _currentFilter == TaskFilter.active
                                  ? 'No active tasks!'
                                  : 'No tasks yet!',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _currentFilter == TaskFilter.completed 
                              ? 'Complete some tasks to see them here'
                              : 'Add a task to get started',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = _filteredTasks[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: _editingTaskIndex == index ? null : () => _startEditingTask(index),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Checkbox
                                  GestureDetector(
                                    onTap: () => _toggleTask(index),
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: task.isCompleted ? Colors.green : Colors.grey,
                                          width: 2,
                                        ),
                                        color: task.isCompleted ? Colors.green : Colors.transparent,
                                      ),
                                      child: task.isCompleted
                                          ? const Icon(
                                              Icons.check,
                                              size: 16,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Task content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _editingTaskIndex == index
                                            ? TextField(
                                                controller: _editController,
                                                autofocus: true,
                                                decoration: const InputDecoration(
                                                  border: OutlineInputBorder(),
                                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                ),
                                                onSubmitted: (_) => _saveEditedTask(),
                                              )
                                            : Text(
                                                task.title,
                                                style: TextStyle(
                                                  decoration: task.isCompleted
                                                      ? TextDecoration.lineThrough
                                                      : TextDecoration.none,
                                                  color: task.isCompleted
                                                      ? Colors.grey
                                                      : Colors.black87,
                                                  fontSize: 16,
                                                ),
                                              ),
                                        const SizedBox(height: 4),
                                        // Category Chip
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: task.category.color.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: task.category.color.withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                task.category.icon,
                                                size: 12,
                                                color: task.category.color,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                task.category.displayName,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: task.category.color,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Action buttons
                                  if (_editingTaskIndex == index)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GestureDetector(
                                          onTap: _saveEditedTask,
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            child: const Icon(
                                              Icons.check,
                                              color: Colors.green,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: _cancelEditing,
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    GestureDetector(
                                      onTap: () => _deleteTask(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        child: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Stats and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$_remainingTasks tasks remaining',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      'Total: ${_tasks.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Filter Tabs
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: TaskFilter.values.map((filter) {
                      final isSelected = _currentFilter == filter;
                      return Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () => _setFilter(filter),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.blue : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _getFilterDisplayName(filter),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey[600],
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _taskController.dispose();
    _editController.dispose();
    _taskFocusNode.dispose();
    super.dispose();
  }
}
