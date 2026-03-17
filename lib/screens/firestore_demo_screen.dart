import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

// Activity log model for real-time tracking
class ActivityLog {
  final String message;
  final String type;
  final DateTime timestamp;
  
  ActivityLog({
    required this.message,
    required this.type,
    required this.timestamp,
  });
}

class FirestoreDemoScreen extends StatefulWidget {
  const FirestoreDemoScreen({super.key});

  @override
  State<FirestoreDemoScreen> createState() => _FirestoreDemoScreenState();
}

class _FirestoreDemoScreenState extends State<FirestoreDemoScreen> with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priorityController = TextEditingController(text: '5');
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  
  // State variables
  bool _isLoading = false;
  String? _editingTaskId;
  
  // Query state for filtering and sorting
  String _selectedFilter = 'all'; // all, active, completed, high_priority, important_tags
  String _selectedSort = 'createdAt_desc'; // createdAt_asc, createdAt_desc, title_asc, title_desc
  int _selectedLimit = 10; // 5, 10, 20, 50
  
  // Real-time sync state
  StreamSubscription<QuerySnapshot>? _tasksSubscription;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  List<ActivityLog> _activityLogs = [];
  bool _isRealTimeActive = true;
  int _realTimeUpdateCount = 0;
  
  // Document-level listeners
  final Map<String, StreamSubscription<DocumentSnapshot>> _documentListeners = {};
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }
  
  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _fadeController.forward();
    _slideController.forward();
    
    // Start real-time listeners
    _setupRealTimeListeners();
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    
    // Cancel real-time subscriptions
    _tasksSubscription?.cancel();
    _userSubscription?.cancel();
    _documentListeners.forEach((key, subscription) => subscription.cancel());
    _documentListeners.clear();
    
    super.dispose();
  }
  
  // REAL-TIME LISTENERS SETUP
  void _setupRealTimeListeners() {
    _setupCollectionListener();
    _setupUserDocumentListener();
  }
  
  // Collection-level real-time listener
  void _setupCollectionListener() {
    _tasksSubscription = _firestore
        .collection('tasks')
        .where('userId', isEqualTo: _auth.currentUser?.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      // Process document changes
      for (var change in snapshot.docChanges) {
        _handleDocumentChange(change);
      }
      
      // Update real-time counter
      setState(() {
        _realTimeUpdateCount++;
      });
      
      // Trigger pulse animation for visual feedback
      _pulseController.forward().then((_) => _pulseController.reverse());
    });
  }
  
  // Document-level real-time listener for user profile
  void _setupUserDocumentListener() {
    if (_auth.currentUser?.uid != null) {
      _userSubscription = _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          _addActivityLog('User profile updated', 'info');
        }
      });
    }
  }
  
  // Handle individual document changes
  void _handleDocumentChange(DocumentChange change) {
    final data = change.doc.data() as Map<String, dynamic>?;
    final title = data?['title'] ?? 'Unknown Task';
    
    switch (change.type) {
      case DocumentChangeType.added:
        _addActivityLog('New task added: "$title"', 'add');
        _showRealTimeNotification('New task added!', title);
        break;
      case DocumentChangeType.modified:
        _addActivityLog('Task updated: "$title"', 'update');
        _showRealTimeNotification('Task updated!', title);
        break;
      case DocumentChangeType.removed:
        _addActivityLog('Task deleted: "$title"', 'delete');
        _showRealTimeNotification('Task deleted!', title);
        break;
    }
  }
  
  // Add document-level listener for specific task
  void _addDocumentListener(String taskId) {
    // Cancel existing listener for this document
    _documentListeners[taskId]?.cancel();
    
    // Add new listener
    _documentListeners[taskId] = _firestore
        .collection('tasks')
        .doc(taskId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final title = data['title'] ?? 'Unknown Task';
        _addActivityLog('Real-time update for: "$title"', 'realtime');
      }
    });
  }
  
  // Add activity log entry
  void _addActivityLog(String message, String type) {
    setState(() {
      _activityLogs.insert(0, ActivityLog(
        message: message,
        type: type,
        timestamp: DateTime.now(),
      ));
      
      // Keep only last 50 activity logs
      if (_activityLogs.length > 50) {
        _activityLogs = _activityLogs.take(50).toList();
      }
    });
  }
  
  // Show real-time notification
  void _showRealTimeNotification(String title, String subtitle) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1B5E20),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
  
  // Toggle real-time sync
  void _toggleRealTimeSync() {
    if (_isRealTimeActive) {
      _tasksSubscription?.pause();
      _userSubscription?.pause();
      _documentListeners.forEach((key, subscription) => subscription.pause());
    } else {
      _tasksSubscription?.resume();
      _userSubscription?.resume();
      _documentListeners.forEach((key, subscription) => subscription.resume());
    }
    
    setState(() {
      _isRealTimeActive = !_isRealTimeActive;
    });
    
    _addActivityLog(
      _isRealTimeActive ? 'Real-time sync resumed' : 'Real-time sync paused', 
      'info'
    );
  }

  // ADD operation - creates new document with auto-generated ID
  Future<void> _addTask() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      final priority = int.tryParse(_priorityController.text) ?? 5;
      
      // ADD operation with auto-generated ID including priority and tags
      await _firestore.collection('tasks').add({
        'title': title,
        'description': description,
        'isCompleted': false,
        'priority': priority,
        'tags': priority > 7 ? ['important', 'urgent'] : ['normal'],
        'userId': _auth.currentUser?.uid,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      
      _clearForm();
      _showSnackBar('Task added successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('Error adding task: ${e.toString()}', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  // UPDATE operation - modifies specific fields
  Future<void> _updateTask(String taskId) async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      
      // UPDATE operation - modifies only specified fields
      await _firestore.collection('tasks').doc(taskId).update({
        'title': title,
        'description': description,
        'updatedAt': Timestamp.now(),
      });
      
      _clearForm();
      _showSnackBar('Task updated successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('Error updating task: ${e.toString()}', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  // Toggle task completion
  Future<void> _toggleTaskCompletion(String taskId, bool currentStatus) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'isCompleted': !currentStatus,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      _showSnackBar('Error toggling task: ${e.toString()}', Colors.red);
    }
  }
  
  // DELETE operation
  Future<void> _deleteTask(String taskId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).delete();
      _showSnackBar('Task deleted successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('Error deleting task: ${e.toString()}', Colors.red);
    }
  }
  
  // Edit task - populate form with existing data
  void _editTask(DocumentSnapshot task) {
    final data = task.data() as Map<String, dynamic>;
    setState(() {
      _editingTaskId = task.id;
      _titleController.text = data['title'] ?? '';
      _descriptionController.text = data['description'] ?? '';
      _priorityController.text = (data['priority'] ?? 5).toString();
    });
    
    // Add document-level listener for real-time updates on this specific task
    _addDocumentListener(task.id);
  }
  
  // Clear form
  void _clearForm() {
    setState(() {
      _editingTaskId = null;
      _titleController.clear();
      _descriptionController.clear();
      _priorityController.text = '5';
    });
    _formKey.currentState?.reset();
  }
  
  // Show snackbar
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
  
  // QUERY BUILDING METHODS
  Query _buildTasksQuery() {
    Query query = _firestore.collection('tasks');
    
    // Apply where filters based on selection
    switch (_selectedFilter) {
      case 'active':
        query = query.where('isCompleted', isEqualTo: false);
        break;
      case 'completed':
        query = query.where('isCompleted', isEqualTo: true);
        break;
      case 'high_priority':
        query = query.where('priority', isGreaterThan: 5);
        break;
      case 'important_tags':
        query = query.where('tags', arrayContains: 'important');
        break;
      case 'all':
      default:
        // No filter for all tasks
        break;
    }
    
    // Apply user filter
    query = query.where('userId', isEqualTo: _auth.currentUser?.uid);
    
    // Apply orderBy based on selection
    switch (_selectedSort) {
      case 'createdAt_asc':
        query = query.orderBy('createdAt', descending: false);
        break;
      case 'createdAt_desc':
        query = query.orderBy('createdAt', descending: true);
        break;
      case 'title_asc':
        query = query.orderBy('title', descending: false);
        break;
      case 'title_desc':
        query = query.orderBy('title', descending: true);
        break;
      default:
        query = query.orderBy('createdAt', descending: true);
        break;
    }
    
    // Apply limit
    query = query.limit(_selectedLimit);
    
    return query;
  }
  
  // Get query description for UI
  String _getQueryDescription() {
    String filterDesc = '';
    switch (_selectedFilter) {
      case 'active':
        filterDesc = 'Active tasks';
        break;
      case 'completed':
        filterDesc = 'Completed tasks';
        break;
      case 'high_priority':
        filterDesc = 'High priority tasks (priority > 5)';
        break;
      case 'important_tags':
        filterDesc = 'Tasks with "important" tag (arrayContains)';
        break;
      case 'all':
      default:
        filterDesc = 'All tasks';
        break;
    }
    
    String sortDesc = '';
    switch (_selectedSort) {
      case 'createdAt_asc':
        sortDesc = 'oldest first';
        break;
      case 'createdAt_desc':
        sortDesc = 'newest first';
        break;
      case 'title_asc':
        sortDesc = 'A-Z';
        break;
      case 'title_desc':
        sortDesc = 'Z-A';
        break;
      default:
        sortDesc = 'newest first';
        break;
    }
    
    return '$filterDesc, sorted by $sortDesc, limited to $_selectedLimit';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'Real-Time Firestore',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _isRealTimeActive ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1B5E20)),
        actions: [
          // Real-time status indicator
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isRealTimeActive ? Colors.green.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isRealTimeActive ? Colors.green.shade300 : Colors.grey.shade300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isRealTimeActive ? Icons.sync : Icons.sync_disabled,
                  size: 16,
                  color: _isRealTimeActive ? Colors.green.shade700 : Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  '$_realTimeUpdateCount',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _isRealTimeActive ? Colors.green.shade700 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          // Toggle real-time sync
          IconButton(
            onPressed: _toggleRealTimeSync,
            icon: Icon(
              _isRealTimeActive ? Icons.pause_circle : Icons.play_circle,
              color: const Color(0xFF1B5E20),
            ),
            tooltip: _isRealTimeActive ? 'Pause Real-time' : 'Resume Real-time',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Form Section
                _buildFormSection(),
                const SizedBox(height: 32),
                
                // Query Controls Section
                _buildQueryControlsSection(),
                const SizedBox(height: 32),
                
                // Real-time Activity Feed
                _buildActivityFeedSection(),
                const SizedBox(height: 32),
                
                // Tasks List Section
                _buildTasksSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // QUERY CONTROLS SECTION
  Widget _buildQueryControlsSection() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.white, const Color(0xFFF8FFFE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: const Color(0xFF1B5E20),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Firestore Query Controls',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getQueryDescription(),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            
            // Filter Controls
            Text(
              'Where Filters',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterChip('all', 'All Tasks'),
                _buildFilterChip('active', 'Active'),
                _buildFilterChip('completed', 'Completed'),
                _buildFilterChip('high_priority', 'High Priority'),
                _buildFilterChip('important_tags', 'Important Tags'),
              ],
            ),
            const SizedBox(height: 24),
            
            // Sort Controls
            Text(
              'OrderBy Sorting',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSortChip('createdAt_desc', 'Newest First'),
                _buildSortChip('createdAt_asc', 'Oldest First'),
                _buildSortChip('title_asc', 'Title A-Z'),
                _buildSortChip('title_desc', 'Title Z-A'),
              ],
            ),
            const SizedBox(height: 24),
            
            // Limit Controls
            Text(
              'Limit Results',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildLimitChip(5, '5'),
                _buildLimitChip(10, '10'),
                _buildLimitChip(20, '20'),
                _buildLimitChip(50, '50'),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
        _addActivityLog('Filter changed to: $label', 'info');
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: const Color(0xFF1B5E20).withValues(alpha: 0.2),
      checkmarkColor: const Color(0xFF1B5E20),
      labelStyle: GoogleFonts.inter(
        color: isSelected ? const Color(0xFF1B5E20) : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
    );
  }
  
  Widget _buildSortChip(String value, String label) {
    final isSelected = _selectedSort == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedSort = value;
        });
        _addActivityLog('Sort changed to: $label', 'info');
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: const Color(0xFF4CAF50).withValues(alpha: 0.2),
      checkmarkColor: const Color(0xFF4CAF50),
      labelStyle: GoogleFonts.inter(
        color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
    );
  }
  
  Widget _buildLimitChip(int value, String label) {
    final isSelected = _selectedLimit == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedLimit = value;
        });
        _addActivityLog('Limit changed to: $value', 'info');
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: Colors.orange.withValues(alpha: 0.2),
      checkmarkColor: Colors.orange.shade700,
      labelStyle: GoogleFonts.inter(
        color: isSelected ? Colors.orange.shade700 : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
    );
  }
  
  Widget _buildFormSection() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.white, const Color(0xFFF8FFFE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _editingTaskId != null ? 'Edit Task' : 'Add New Task',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _editingTaskId != null 
                  ? 'Update task details below'
                  : 'Fill in the form to add a new task',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),
            
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Task Title',
                      hintText: 'Enter task title',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a task title';
                      }
                      if (value.trim().length < 3) {
                        return 'Title must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Enter task description',
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a task description';
                      }
                      if (value.trim().length < 10) {
                        return 'Description must be at least 10 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _priorityController,
                    decoration: const InputDecoration(
                      labelText: 'Priority (1-10)',
                      hintText: 'Enter task priority',
                      prefixIcon: Icon(Icons.priority_high),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a priority';
                      }
                      final priority = int.tryParse(value);
                      if (priority == null || priority < 1 || priority > 10) {
                        return 'Priority must be between 1 and 10';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _editingTaskId != null 
                              ? () => _updateTask(_editingTaskId!)
                              : _addTask,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(_editingTaskId != null ? 'Update Task' : 'Add Task'),
                        ),
                      ),
                      if (_editingTaskId != null) ...[
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _clearForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade300,
                            foregroundColor: Colors.black87,
                          ),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTasksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Tasks',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 16),
        
        StreamBuilder<QuerySnapshot>(
          stream: _buildTasksQuery().snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
              );
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: GoogleFonts.inter(color: Colors.red),
                ),
              );
            }
            
            final tasks = snapshot.data?.docs ?? [];
            
            if (tasks.isEmpty) {
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.task_alt,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tasks yet',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your first task to get started!',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                final data = task.data() as Map<String, dynamic>;
                final isCompleted = data['isCompleted'] ?? false;
                final priority = data['priority'] ?? 5;
                final tags = List<String>.from(data['tags'] ?? []);
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: isCompleted ? Colors.grey.shade50 : Colors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['title'] ?? 'No Title',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isCompleted ? Colors.grey.shade600 : const Color(0xFF1B5E20),
                                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    data['description'] ?? 'No Description',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: isCompleted ? Colors.grey.shade500 : const Color(0xFF6B7280),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.schedule,
                                        size: 14,
                                        color: Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatTimestamp(data['createdAt']),
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 16),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'toggle',
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle, size: 16),
                                      SizedBox(width: 8),
                                      Text('Toggle Complete'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, size: 16, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                switch (value) {
                                  case 'edit':
                                    _editTask(task);
                                    break;
                                  case 'toggle':
                                    _toggleTaskCompletion(task.id, isCompleted);
                                    break;
                                  case 'delete':
                                    _showDeleteConfirmation(task.id);
                                    break;
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Priority Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: priority > 7 ? Colors.red.shade100 : 
                                       priority > 4 ? Colors.orange.shade100 : Colors.green.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.priority_high,
                                    size: 12,
                                    color: priority > 7 ? Colors.red.shade700 : 
                                           priority > 4 ? Colors.orange.shade700 : Colors.green.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'P$priority',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: priority > 7 ? Colors.red.shade700 : 
                                             priority > 4 ? Colors.orange.shade700 : Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            
                            // Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isCompleted ? Colors.green.shade100 : Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isCompleted ? 'Completed' : 'Active',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isCompleted ? Colors.green.shade700 : Colors.blue.shade700,
                                ),
                              ),
                            ),
                            const Spacer(),
                            
                            // Tags
                            if (tags.isNotEmpty) ...[
                              Wrap(
                                spacing: 4,
                                children: tags.map((tag) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    tag,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.purple.shade700,
                                    ),
                                  ),
                                )).toList(),
                              ),
                              const SizedBox(width: 8),
                            ],
                            
                            if (data['userId'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'User Task',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF1B5E20),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
  
  // ACTIVITY FEED SECTION
  Widget _buildActivityFeedSection() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.white, const Color(0xFFF8FFFE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timeline,
                  color: const Color(0xFF1B5E20),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Real-Time Activity Feed',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isRealTimeActive ? Colors.green.shade100 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isRealTimeActive ? 'LIVE' : 'PAUSED',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _isRealTimeActive ? Colors.green.shade700 : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_activityLogs.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.history,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No activity yet',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      'Add, edit, or delete tasks to see real-time updates',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                height: 200,
                child: ListView.builder(
                  itemCount: _activityLogs.length > 10 ? 10 : _activityLogs.length,
                  itemBuilder: (context, index) {
                    final activity = _activityLogs[index];
                    return _buildActivityItem(activity);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActivityItem(ActivityLog activity) {
    Color iconColor;
    IconData iconData;
    
    switch (activity.type) {
      case 'add':
        iconColor = Colors.green;
        iconData = Icons.add_circle;
        break;
      case 'update':
        iconColor = Colors.blue;
        iconData = Icons.edit;
        break;
      case 'delete':
        iconColor = Colors.red;
        iconData = Icons.delete;
        break;
      case 'realtime':
        iconColor = Colors.purple;
        iconData = Icons.sync;
        break;
      default:
        iconColor = Colors.grey;
        iconData = Icons.info;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            iconData,
            color: iconColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.message,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatActivityTimestamp(activity.timestamp),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatActivityTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showDeleteConfirmation(String taskId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Task',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete this task? This action cannot be undone.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTask(taskId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'No date';
    
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
