# Firestore Write Operations - PlantPulse App

## Project Overview

This implementation demonstrates secure Firestore write operations in the PlantPulse Flutter application. The app showcases **ADD**, **SET**, **UPDATE**, and **DELETE** operations with proper validation, error handling, and user feedback.

## Firebase Configuration

### Dependencies
```yaml
dependencies:
  firebase_core: ^3.0.0
  firebase_auth: ^5.0.0
  cloud_firestore: ^5.0.0
```

### Initialization
```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const PlantPulseApp());
}
```

## Firestore Write Operations

### 1. ADD Operation (Auto-generated ID)
Creates a new document with a unique auto-generated ID.

```dart
Future<void> _addTask() async {
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
  }
}
```

### 2. SET Operation (Specific Document ID)
Writes to a specific document ID, overwriting the entire document.

```dart
Future<void> _setTask(String taskId) async {
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
  }
}
```

### 3. UPDATE Operation (Partial Updates)
Modifies only specific fields in an existing document.

```dart
Future<void> _updateTask(String taskId) async {
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
  }
}
```

### 4. DELETE Operation
Removes a document from the collection.

```dart
Future<void> _deleteTask(String taskId) async {
  try {
    await _firestore.collection('tasks').doc(taskId).delete();
    _showSnackBar('Task deleted successfully!', Colors.green);
  } catch (e) {
    _showSnackBar('Error deleting task: ${e.toString()}', Colors.red);
  }
}
```

## Input Form with Validation

### Form Implementation
```dart
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
      
      ElevatedButton(
        onPressed: _isLoading ? null : _editingTaskId != null 
            ? () => _updateTask(_editingTaskId!)
            : _addTask,
        child: _isLoading
            ? const CircularProgressIndicator()
            : Text(_editingTaskId != null ? 'Update Task' : 'Add Task'),
      ),
    ],
  ),
)
```

## Real-time Data Display

### StreamBuilder Implementation
```dart
StreamBuilder<QuerySnapshot>(
  stream: _firestore
      .collection('tasks')
      .where('userId', isEqualTo: _auth.currentUser?.uid)
      .orderBy('createdAt', descending: true)
      .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const CircularProgressIndicator();
    }
    
    if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    }
    
    final tasks = snapshot.data?.docs ?? [];
    
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final data = task.data() as Map<String, dynamic>;
        
        return TaskCard(
          task: task,
          data: data,
          onEdit: () => _editTask(task),
          onDelete: () => _deleteTask(task.id),
          onToggleComplete: () => _toggleTaskCompletion(task.id, data['isCompleted']),
        );
      },
    );
  },
)
```

## Secure Write Practices

### 1. Input Validation
- **Non-empty fields**: All required fields must have content
- **Length validation**: Minimum character requirements
- **Data type validation**: Ensure correct data types
- **User authentication**: Only authenticated users can write data

### 2. Data Structure
```dart
{
  'title': 'String',           // Required
  'description': 'String',     // Required
  'isCompleted': 'Boolean',    // Default: false
  'userId': 'String',          // User authentication
  'createdAt': 'Timestamp',    // Auto-generated
  'updatedAt': 'Timestamp',    // Auto-updated
}
```

### 3. Error Handling
- **Try-catch blocks**: Handle all Firestore operations
- **User feedback**: Show success/error messages
- **Loading states**: Prevent duplicate operations
- **Graceful degradation**: Handle network issues

### 4. Security Best Practices
- **User-based filtering**: Only show user's own data
- **Field validation**: Server-side validation in Firestore rules
- **Timestamp tracking**: Track creation and modification times
- **Partial updates**: Use `update()` instead of `set()` when possible

## Operation Differences

| Operation | Use Case | ID Handling | Overwrites | Best Practice |
|-----------|-----------|-------------|------------|---------------|
| **ADD** | New documents | Auto-generated | No | Creating new records |
| **SET** | Specific ID control | Manual | Yes | Complete document replacement |
| **UPDATE** | Partial modifications | Existing document | No | Modifying specific fields |
| **DELETE** | Removal | Existing document | N/A | Cleaning up data |

## App Features

### 1. Task Management
- **Add new tasks** with title and description
- **Edit existing tasks** with pre-filled forms
- **Mark tasks as complete/incomplete**
- **Delete tasks** with confirmation dialog

### 2. Real-time Sync
- **Live updates** when data changes
- **Stream-based** data fetching
- **Automatic UI refresh** on data changes

### 3. User Experience
- **Form validation** with error messages
- **Loading indicators** during operations
- **Success/error feedback** via SnackBars
- **Responsive design** for all screen sizes

## Testing Instructions

### 1. Manual Testing
1. **Login to the app**
2. **Navigate to Firestore Demo** (storage icon in dashboard)
3. **Add a new task**:
   - Fill in title and description
   - Click "Add Task"
   - Verify success message
4. **Check Firebase Console**:
   - Navigate to Firestore Database
   - Look in "tasks" collection
   - Verify new document with correct fields
5. **Edit the task**:
   - Click menu (⋮) on task card
   - Select "Edit"
   - Modify fields
   - Click "Update Task"
   - Verify updated data in console
6. **Toggle completion**:
   - Click menu (⋮) on task card
   - Select "Toggle Complete"
   - Verify isCompleted field changes
7. **Delete task**:
   - Click menu (⋮) on task card
   - Select "Delete"
   - Confirm deletion
   - Verify document removed from console

### 2. Firebase Console Verification
- **Collection**: `tasks`
- **Document Structure**:
  ```json
  {
    "title": "Learn Flutter",
    "description": "Complete Firestore operations tutorial",
    "isCompleted": false,
    "userId": "user-uid-here",
    "createdAt": "2024-03-16T12:00:00Z",
    "updatedAt": "2024-03-16T12:00:00Z"
  }
  ```

## Security Rules (Recommended)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own tasks
    match /tasks/{taskId} {
      allow read, write, delete: if request.auth != null && 
        request.auth.uid == resource.data.userId;
      allow create: if request.auth != null && 
        request.auth.uid == request.resource.data.userId;
    }
  }
}
```

## Reflection

### Why Secure Writes Matter
1. **Data Integrity**: Prevents corrupt or incomplete data
2. **User Privacy**: Ensures users only access their own data
3. **Performance**: Efficient operations reduce database load
4. **Scalability**: Proper structure supports app growth

### Validation Benefits
1. **Prevents Data Corruption**: Ensures data quality
2. **User Experience**: Clear error messages guide users
3. **Security**: Blocks malicious input
4. **Consistency**: Maintains uniform data structure

### Operation Selection
- **ADD**: Use when you don't need to control the document ID
- **SET**: Use when you need a specific document ID or want to replace entire documents
- **UPDATE**: Use for partial modifications to preserve existing data
- **DELETE**: Use for complete data removal with confirmation

## Screenshots

### App UI Screenshots
1. **Firestore Demo Screen**: Form and task list
2. **Add Task Form**: Validation and submission
3. **Task List**: Real-time data display
4. **Edit Task**: Pre-filled form for updates
5. **Success Messages**: User feedback

### Firebase Console Screenshots
1. **Tasks Collection**: Document listing
2. **Document Structure**: Field values and timestamps
3. **Real-time Updates**: Changes reflected immediately

## Video Demo

The 1-2 minute video demonstration includes:
1. **Adding a task** - Form filling and submission
2. **Firebase Console verification** - New document appears
3. **Updating a task** - Edit and save changes
4. **Real-time sync** - UI updates automatically
5. **Deleting a task** - Confirmation and removal

## Technical Implementation

### File Structure
```
lib/
├── screens/
│   ├── firestore_demo_screen.dart    # Main implementation
│   └── dashboard.dart                 # Navigation integration
├── main.dart                          # Firebase initialization
└── services/
    ├── firebase_service.dart          # Auth service
    └── firestore_service.dart         # Firestore operations
```

### Key Components
- **FirestoreDemoScreen**: Main UI and operations
- **Form validation**: Input checking and error handling
- **StreamBuilder**: Real-time data updates
- **Error handling**: Comprehensive try-catch blocks
- **User feedback**: SnackBar notifications

This implementation provides a complete, production-ready example of secure Firestore write operations with proper validation, error handling, and user experience considerations.
