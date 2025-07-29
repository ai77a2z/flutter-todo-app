import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatefulWidget {
  const TodoApp({super.key});

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode = _themeMode == ThemeMode.light 
          ? ThemeMode.dark 
          : ThemeMode.light;
    });
    await prefs.setBool('isDarkMode', _themeMode == ThemeMode.dark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Todo App',
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: TodoHomePage(
        onThemeToggle: _toggleTheme,
        isDarkMode: _themeMode == ThemeMode.dark,
      ),
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

// Task priority enum
enum TaskPriority {
  low,
  medium, 
  high
}

// Extension to get priority properties
extension TaskPriorityExtension on TaskPriority {
  String get displayName {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case TaskPriority.low:
        return Icons.arrow_downward;
      case TaskPriority.medium:
        return Icons.remove;
      case TaskPriority.high:
        return Icons.arrow_upward;
    }
  }

  int get sortOrder {
    switch (this) {
      case TaskPriority.high:
        return 3;
      case TaskPriority.medium:
        return 2;
      case TaskPriority.low:
        return 1;
    }
  }
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
  TaskPriority priority;
  DateTime? dueDate;
  
  Task({
    required this.title, 
    this.isCompleted = false,
    this.category = TaskCategory.personal,
    this.priority = TaskPriority.medium,
    this.dueDate,
  });

  // Helper methods for due date status
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return dueDate!.isBefore(DateTime.now().subtract(const Duration(days: 1)));
  }

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year && 
           dueDate!.month == now.month && 
           dueDate!.day == now.day;
  }

  bool get isDueSoon {
    if (dueDate == null || isCompleted) return false;
    final now = DateTime.now();
    final difference = dueDate!.difference(now).inDays;
    return difference >= 0 && difference <= 3;
  }

  // Convert Task to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'isCompleted': isCompleted,
      'category': category.name,
      'priority': priority.name,
      'dueDate': dueDate?.millisecondsSinceEpoch,
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
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      dueDate: json['dueDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['dueDate'])
          : null,
    );
  }
}

class TodoHomePage extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;

  const TodoHomePage({super.key, required this.onThemeToggle, required this.isDarkMode});

  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _editController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _taskFocusNode = FocusNode();
  final List<Task> _tasks = [];
  TaskFilter _currentFilter = TaskFilter.all;
  TaskCategory _selectedCategory = TaskCategory.personal;
  TaskPriority _selectedPriority = TaskPriority.medium;
  DateTime? _selectedDueDate;
  String _searchQuery = '';
  bool _isSearching = false;
  bool _isBulkSelecting = false;
  Set<String> _selectedTaskIds = {};
  int? _editingTaskIndex; // Track which task is being edited
  TaskCategory? _editingCategory;
  TaskPriority? _editingPriority;
  DateTime? _editingDueDate;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    // Ensure focus after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _taskFocusNode.requestFocus();
    });
  }

  // Get filtered tasks based on current filter and search query
  List<Task> get _filteredTasks {
    List<Task> filtered;
    switch (_currentFilter) {
      case TaskFilter.active:
        filtered = _tasks.where((task) => !task.isCompleted).toList();
        break;
      case TaskFilter.completed:
        filtered = _tasks.where((task) => task.isCompleted).toList();
        break;
      case TaskFilter.all:
      default:
        filtered = _tasks;
        break;
    }
    
    // Apply search filter if search query is not empty
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((task) {
        return task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               task.category.displayName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // Only apply automatic sorting when filters or search are active
    // This preserves custom user ordering when viewing all tasks
    if (_currentFilter != TaskFilter.all || _searchQuery.isNotEmpty) {
      // Sort by priority (high to low) and then by due date
      filtered.sort((a, b) {
        // First sort by completion status (incomplete tasks first)
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        
        // Then sort by priority (high to low)
        if (a.priority.sortOrder != b.priority.sortOrder) {
          return b.priority.sortOrder.compareTo(a.priority.sortOrder);
        }
        
        // Finally sort by due date (closest first)
        if (a.dueDate != null && b.dueDate != null) {
          return a.dueDate!.compareTo(b.dueDate!);
        } else if (a.dueDate != null) {
          return -1; // Tasks with due dates come first
        } else if (b.dueDate != null) {
          return 1;
        }
        
        return 0;
      });
    }
    
    return filtered;
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _startBulkSelection() {
    setState(() {
      _isBulkSelecting = true;
      _selectedTaskIds.clear();
    });
  }

  void _stopBulkSelection() {
    setState(() {
      _isBulkSelecting = false;
      _selectedTaskIds.clear();
    });
  }

  void _toggleTaskSelection(String taskId) {
    setState(() {
      if (_selectedTaskIds.contains(taskId)) {
        _selectedTaskIds.remove(taskId);
      } else {
        _selectedTaskIds.add(taskId);
      }
    });
  }

  void _selectAllTasks() {
    setState(() {
      _selectedTaskIds.clear();
      for (var task in _filteredTasks) {
        _selectedTaskIds.add(task.title + task.hashCode.toString());
      }
    });
  }

  void _bulkCompleteSelected() {
    setState(() {
      for (var task in _tasks) {
        final taskId = task.title + task.hashCode.toString();
        if (_selectedTaskIds.contains(taskId)) {
          task.isCompleted = true;
        }
      }
      _selectedTaskIds.clear();
      _isBulkSelecting = false;
    });
    _saveTasks();
  }

  void _bulkDeleteSelected() async {
    final shouldDelete = await _showBulkDeleteConfirmation();
    if (shouldDelete) {
      setState(() {
        _tasks.removeWhere((task) {
          final taskId = task.title + task.hashCode.toString();
          return _selectedTaskIds.contains(taskId);
        });
        _selectedTaskIds.clear();
        _isBulkSelecting = false;
      });
      _saveTasks();
    }
  }

  void _clearAllCompleted() async {
    final completedTasks = _tasks.where((task) => task.isCompleted).toList();
    if (completedTasks.isEmpty) return;

    final shouldClear = await _showClearCompletedConfirmation(completedTasks.length);
    if (shouldClear) {
      setState(() {
        _tasks.removeWhere((task) => task.isCompleted);
      });
      _saveTasks();
    }
  }

  Future<bool> _showBulkDeleteConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Tasks'),
        content: Text('Are you sure you want to delete ${_selectedTaskIds.length} selected tasks?'),
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
    ) ?? false;
  }

  Future<bool> _showClearCompletedConfirmation(int count) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Completed Tasks'),
        content: Text('Are you sure you want to delete $count completed tasks?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _selectEditingDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _editingDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.blue,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _editingDueDate = picked;
      });
    }
  }

  void _clearEditingDueDate() {
    setState(() {
      _editingDueDate = null;
    });
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
        _tasks.add(Task(
          title: _taskController.text.trim(), 
          category: _selectedCategory,
          priority: _selectedPriority,
          dueDate: _selectedDueDate,
        ));
        _taskController.clear();
        _selectedDueDate = null; // Reset due date after adding
      });
      _saveTasks();
      // Refocus the input field after adding a task
      _taskFocusNode.requestFocus();
    }
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.blue,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  void _clearDueDate() {
    setState(() {
      _selectedDueDate = null;
    });
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference == -1) {
      return 'Yesterday';
    } else if (difference < -1) {
      return '${difference.abs()} days ago';
    } else {
      return 'In $difference days';
    }
  }

  Color _getDueDateColor(Task task) {
    if (task.dueDate == null || task.isCompleted) return Colors.grey;
    
    if (task.isOverdue) return Colors.red;
    if (task.isDueToday) return Colors.orange;
    if (task.isDueSoon) return Colors.blue;
    return Colors.grey;
  }

  Future<bool> _showDeleteConfirmation(BuildContext context, String taskTitle) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "$taskTitle"?'),
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
    ) ?? false;
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
      _editingCategory = task.category;
      _editingPriority = task.priority;
      _editingDueDate = task.dueDate;
    });
  }

  void _saveEditedTask() {
    if (_editingTaskIndex != null && _editController.text.trim().isNotEmpty) {
      final task = _filteredTasks[_editingTaskIndex!];
      final mainIndex = _tasks.indexOf(task);
      
      setState(() {
        _tasks[mainIndex].title = _editController.text.trim();
        _tasks[mainIndex].category = _editingCategory!;
        _tasks[mainIndex].priority = _editingPriority!;
        _tasks[mainIndex].dueDate = _editingDueDate;
        _editingTaskIndex = null;
        _editController.clear();
        _editingCategory = null;
        _editingPriority = null;
        _editingDueDate = null;
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
      _editingCategory = null;
      _editingPriority = null;
      _editingDueDate = null;
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

  // Helper to reorder tasks in the main _tasks list
  void _reorderTasksInMainList() {
    // This is a complex operation when filtering is active
    // For now, we'll only allow reordering when no filters are active
    if (_currentFilter != TaskFilter.all || _searchQuery.isNotEmpty) {
      return; // Don't reorder when filters are active
    }
    
    // Simple case: reorder the main tasks list directly
    final List<Task> newOrder = List.from(_filteredTasks);
    setState(() {
      _tasks.clear();
      _tasks.addAll(newOrder);
    });
  }

  void _handleReorder(int oldIndex, int newIndex) {
    // Only allow reordering when showing all tasks without search
    if (_currentFilter != TaskFilter.all || _searchQuery.isNotEmpty) {
      // Show a message that reordering is only available for all tasks
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reordering is only available when viewing all tasks'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final task = _tasks.removeAt(oldIndex);
      _tasks.insert(newIndex, task);
    });
    _saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.inversePrimary,
        title: Text(
          _isSearching ? '' : 'Todo App v2.0',
          style: TextStyle(color: colorScheme.onInverseSurface),
        ),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          if (_isSearching)
            IconButton(
              onPressed: _stopSearch,
              icon: const Icon(Icons.close, color: Colors.white),
              tooltip: 'Close Search',
            )
          else if (_isBulkSelecting)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_selectedTaskIds.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                IconButton(
                  onPressed: _stopBulkSelection,
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: 'Cancel Selection',
                ),
              ],
            )
          else
            IconButton(
              onPressed: _startSearch,
              icon: const Icon(Icons.search, color: Colors.white),
              tooltip: 'Search Tasks',
            ),
          // Overflow menu
          if (!_isSearching && !_isBulkSelecting)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                switch (value) {
                  case 'bulk_select':
                    _startBulkSelection();
                    break;
                  case 'clear_completed':
                    _clearAllCompleted();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'bulk_select',
                  child: Row(
                    children: [
                      Icon(Icons.checklist),
                      SizedBox(width: 8),
                      Text('Select Multiple'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear_completed',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all),
                      SizedBox(width: 8),
                      Text('Clear Completed'),
                    ],
                  ),
                ),
              ],
            ),
          // Theme toggle
          IconButton(
            onPressed: widget.onThemeToggle,
            icon: Icon(
              widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
            ),
            tooltip: widget.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
          ),
        ],
      ),
      body: Column(
        children: [
          // Input Section
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.1),
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
                const SizedBox(height: 8),
                // Priority Selection Row
                Row(
                  children: [
                    const Text(
                      'Priority:',
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
                          color: _selectedPriority.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _selectedPriority.color.withOpacity(0.3),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<TaskPriority>(
                            value: _selectedPriority,
                            isExpanded: true,
                            icon: Icon(Icons.arrow_drop_down, color: _selectedPriority.color),
                            style: TextStyle(color: _selectedPriority.color, fontSize: 14),
                            onChanged: (TaskPriority? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedPriority = newValue;
                                });
                              }
                            },
                            items: TaskPriority.values.map<DropdownMenuItem<TaskPriority>>((TaskPriority priority) {
                              return DropdownMenuItem<TaskPriority>(
                                value: priority,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      priority.icon,
                                      size: 16,
                                      color: priority.color,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(priority.displayName),
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
                const SizedBox(height: 8),
                // Due Date Selection Row
                Row(
                  children: [
                    const Text(
                      'Due Date:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: _selectDueDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedDueDate != null 
                                  ? Colors.blue.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _selectedDueDate != null 
                                    ? Colors.blue.withOpacity(0.3)
                                    : Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: _selectedDueDate != null ? Colors.blue : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selectedDueDate != null 
                                        ? _formatDueDate(_selectedDueDate!)
                                        : 'No due date',
                                    style: TextStyle(
                                      color: _selectedDueDate != null ? Colors.blue : Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                if (_selectedDueDate != null)
                                  GestureDetector(
                                    onTap: _clearDueDate,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      child: const Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
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
                          _searchQuery.isNotEmpty
                              ? Icons.search_off
                              : _currentFilter == TaskFilter.completed 
                                  ? Icons.task_alt 
                                  : Icons.check_circle_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
            Text(
                          _searchQuery.isNotEmpty
                              ? 'No tasks found for "$_searchQuery"'
                              : _currentFilter == TaskFilter.completed 
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
                          _searchQuery.isNotEmpty
                              ? 'Try adjusting your search terms'
                              : _currentFilter == TaskFilter.completed 
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
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredTasks.length,
                    buildDefaultDragHandles: false,
                    onReorder: _handleReorder,
                    itemBuilder: (context, index) {
                      final task = _filteredTasks[index];
                      return Dismissible(
                        key: Key('${task.title}_${task.hashCode}'),
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: task.isCompleted ? Colors.orange : Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          child: Row(
                            children: [
                              Icon(
                                task.isCompleted ? Icons.undo : Icons.check, 
                                color: Colors.white, 
                                size: 24
                              ),
                              const SizedBox(width: 8),
                              Text(
                                task.isCompleted ? 'Uncomplete' : 'Complete',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        secondaryBackground: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Delete',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.delete, color: Colors.white, size: 24),
                            ],
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            // Swipe right to complete/uncomplete
                            _toggleTask(index);
                            return false; // Don't dismiss, just toggle
                          } else if (direction == DismissDirection.endToStart) {
                            // Swipe left to delete
                            return await _showDeleteConfirmation(context, task.title);
                          }
                          return false;
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.shadow.withOpacity(0.1),
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
                                    // Selection checkbox (in bulk mode) or regular checkbox
                                    if (_isBulkSelecting)
                                      GestureDetector(
                                        onTap: () => _toggleTaskSelection(task.title + task.hashCode.toString()),
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: _selectedTaskIds.contains(task.title + task.hashCode.toString()) 
                                                  ? Colors.blue 
                                                  : Colors.grey,
                                              width: 2,
                                            ),
                                            color: _selectedTaskIds.contains(task.title + task.hashCode.toString()) 
                                                ? Colors.blue 
                                                : Colors.transparent,
                                          ),
                                          child: _selectedTaskIds.contains(task.title + task.hashCode.toString())
                                              ? const Icon(
                                                  Icons.check,
                                                  size: 16,
                                                  color: Colors.white,
                                                )
                                              : null,
                                        ),
                                      )
                                    else
                                      // Regular completion checkbox
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
                                      child: GestureDetector(
                                        onTap: _isBulkSelecting 
                                            ? () => _toggleTaskSelection(task.title + task.hashCode.toString())
                                            : _editingTaskIndex == index 
                                                ? null 
                                                : () => _startEditingTask(index),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _editingTaskIndex == index
                                                ? Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      // Title editing
                                                      TextField(
                                                        controller: _editController,
                                                        style: const TextStyle(fontSize: 16),
                                                        decoration: const InputDecoration(
                                                          border: OutlineInputBorder(),
                                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          isDense: true,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      // Category editing
                                                      Row(
                                                        children: [
                                                          const Text('Category: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                                          Expanded(
                                                            child: Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                              decoration: BoxDecoration(
                                                                color: _editingCategory!.color.withOpacity(0.1),
                                                                borderRadius: BorderRadius.circular(6),
                                                                border: Border.all(color: _editingCategory!.color.withOpacity(0.3)),
                                                              ),
                                                              child: DropdownButtonHideUnderline(
                                                                child: DropdownButton<TaskCategory>(
                                                                  value: _editingCategory,
                                                                  isExpanded: true,
                                                                  isDense: true,
                                                                  style: TextStyle(color: _editingCategory!.color, fontSize: 12),
                                                                  onChanged: (TaskCategory? newValue) {
                                                                    if (newValue != null) {
                                                                      setState(() {
                                                                        _editingCategory = newValue;
                                                                      });
                                                                    }
                                                                  },
                                                                  items: TaskCategory.values.map<DropdownMenuItem<TaskCategory>>((TaskCategory category) {
                                                                    return DropdownMenuItem<TaskCategory>(
                                                                      value: category,
                                                                      child: Row(
                                                                        mainAxisSize: MainAxisSize.min,
                                                                        children: [
                                                                          Icon(category.icon, size: 14, color: category.color),
                                                                          const SizedBox(width: 4),
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
                                                      const SizedBox(height: 4),
                                                      // Priority editing
                                                      Row(
                                                        children: [
                                                          const Text('Priority: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                                          Expanded(
                                                            child: Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                              decoration: BoxDecoration(
                                                                color: _editingPriority!.color.withOpacity(0.1),
                                                                borderRadius: BorderRadius.circular(6),
                                                                border: Border.all(color: _editingPriority!.color.withOpacity(0.3)),
                                                              ),
                                                              child: DropdownButtonHideUnderline(
                                                                child: DropdownButton<TaskPriority>(
                                                                  value: _editingPriority,
                                                                  isExpanded: true,
                                                                  isDense: true,
                                                                  style: TextStyle(color: _editingPriority!.color, fontSize: 12),
                                                                  onChanged: (TaskPriority? newValue) {
                                                                    if (newValue != null) {
                                                                      setState(() {
                                                                        _editingPriority = newValue;
                                                                      });
                                                                    }
                                                                  },
                                                                  items: TaskPriority.values.map<DropdownMenuItem<TaskPriority>>((TaskPriority priority) {
                                                                    return DropdownMenuItem<TaskPriority>(
                                                                      value: priority,
                                                                      child: Row(
                                                                        mainAxisSize: MainAxisSize.min,
                                                                        children: [
                                                                          Icon(priority.icon, size: 14, color: priority.color),
                                                                          const SizedBox(width: 4),
                                                                          Text(priority.displayName),
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
                                                      const SizedBox(height: 4),
                                                      // Due date editing
                                                      Row(
                                                        children: [
                                                          const Text('Due Date: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                                          Expanded(
                                                            child: GestureDetector(
                                                              onTap: _selectEditingDueDate,
                                                              child: Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                decoration: BoxDecoration(
                                                                  color: _editingDueDate != null ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                                                  borderRadius: BorderRadius.circular(6),
                                                                  border: Border.all(color: _editingDueDate != null ? Colors.blue.withOpacity(0.3) : Colors.grey.withOpacity(0.3)),
                                                                ),
                                                                child: Row(
                                                                  children: [
                                                                    Icon(Icons.calendar_today, size: 12, color: _editingDueDate != null ? Colors.blue : Colors.grey),
                                                                    const SizedBox(width: 4),
                                                                    Expanded(
                                                                      child: Text(
                                                                        _editingDueDate != null ? _formatDueDate(_editingDueDate!) : 'No due date',
                                                                        style: TextStyle(
                                                                          color: _editingDueDate != null ? Colors.blue : Colors.grey,
                                                                          fontSize: 12,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    if (_editingDueDate != null)
                                                                      GestureDetector(
                                                                        onTap: _clearEditingDueDate,
                                                                        child: const Icon(Icons.close, size: 12, color: Colors.grey),
                                                                      ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  )
                                              : Text(
                                                task.title,
                                                style: TextStyle(
                                                  decoration: task.isCompleted
                                                      ? TextDecoration.lineThrough
                                                      : TextDecoration.none,
                                                  color: task.isCompleted
                                                      ? colorScheme.onSurface.withOpacity(0.6)
                                                      : colorScheme.onSurface,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            const SizedBox(height: 4),
                                            // Category, Priority, and Due Date Row
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 4,
                                              children: [
                                                // Priority Chip (shown first for importance)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: task.priority.color.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: task.priority.color.withOpacity(0.3),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        task.priority.icon,
                                                        size: 12,
                                                        color: task.priority.color,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        task.priority.displayName,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: task.priority.color,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
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
                                                // Due Date Chip
                                                if (task.dueDate != null)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: _getDueDateColor(task).withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(
                                                        color: _getDueDateColor(task).withOpacity(0.3),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          task.isOverdue 
                                                              ? Icons.warning 
                                                              : task.isDueToday 
                                                                  ? Icons.today 
                                                                  : Icons.schedule,
                                                          size: 12,
                                                          color: _getDueDateColor(task),
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          _formatDueDate(task.dueDate!),
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: _getDueDateColor(task),
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
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
                                  else if (!_isBulkSelecting)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Delete button
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
                                        // Drag handle (only show when reordering is available)
                                        if (_currentFilter == TaskFilter.all && _searchQuery.isEmpty)
                                          ReorderableDragStartListener(
                                            index: index,
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              child: Icon(
                                                Icons.drag_indicator,
                                                color: colorScheme.onSurface.withOpacity(0.5),
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bulk Actions Bar (shows when tasks are selected)
          if (_isBulkSelecting && _selectedTaskIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                border: Border(
                  top: BorderSide(color: Colors.blue.withOpacity(0.3)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        TextButton.icon(
                          onPressed: _selectAllTasks,
                          icon: const Icon(Icons.select_all, size: 18),
                          label: const Text('All'),
                          style: TextButton.styleFrom(foregroundColor: Colors.blue),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: _bulkCompleteSelected,
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text('Complete'),
                          style: TextButton.styleFrom(foregroundColor: Colors.green),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _bulkDeleteSelected,
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ),

          // Bottom Stats and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.1),
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
                    color: colorScheme.surfaceContainer,
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
    _searchController.dispose();
    _taskFocusNode.dispose();
    super.dispose();
  }
}
