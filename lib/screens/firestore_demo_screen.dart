import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // State variables
  bool _isLoading = false;
  String? _editingTaskId;
  
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
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    
    _fadeController.forward();
    _slideController.forward();
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }
  
  // ADD operation - creates new document with auto-generated ID
  Future<void> _addTask() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      
      // ADD operation with auto-generated ID
      await _firestore.collection('tasks').add({
        'title': title,
        'description': description,
        'isCompleted': false,
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
  
  // SET operation - writes to specific document ID
  Future<void> _setTask(String taskId) async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      
      // SET operation - overwrites entire document
      await _firestore.collection('tasks').doc(taskId).set({
        'title': title,
        'description': description,
        'isCompleted': false,
        'userId': _auth.currentUser?.uid,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      
      _clearForm();
      _showSnackBar('Task set successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('Error setting task: ${e.toString()}', Colors.red);
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
    });
  }
  
  // Clear form
  void _clearForm() {
    setState(() {
      _editingTaskId = null;
      _titleController.clear();
      _descriptionController.clear();
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: AppBar(
        title: Text(
          'Firestore Operations',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1B5E20),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1B5E20)),
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
                
                // Tasks List Section
                _buildTasksSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildFormSection() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
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
          stream: _firestore
              .collection('tasks')
              .where('userId', isEqualTo: _auth.currentUser?.uid)
              .orderBy('createdAt', descending: true)
              .snapshots(),
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
                            if (data['userId'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B5E20).withOpacity(0.1),
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
