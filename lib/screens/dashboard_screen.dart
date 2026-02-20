import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../services/firestore_service.dart';
import 'widget_tree_demo.dart';

class DashboardScreen extends StatefulWidget {
  final User user;
  final VoidCallback? toggleTheme;
  
  const DashboardScreen({super.key, required this.user, this.toggleTheme});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _plantNameController = TextEditingController();
  final TextEditingController _plantTypeController = TextEditingController();
  
  @override
  void dispose() {
    _plantNameController.dispose();
    _plantTypeController.dispose();
    super.dispose();
  }

  Future<void> _addPlant() async {
    if (_plantNameController.text.isEmpty || _plantTypeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final plantData = {
      'name': _plantNameController.text.trim(),
      'type': _plantTypeController.text.trim(),
      'createdAt': DateTime.now().toIso8601String(),
      'lastWatered': DateTime.now().toIso8601String(),
    };

    await _firestoreService.addPlantData(widget.user.uid, plantData);
    
    _plantNameController.clear();
    _plantTypeController.clear();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Plant added successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _logout() async {
    await _authService.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PlantPulse Dashboard'),
        backgroundColor: Colors.green,
        actions: [
          // Theme toggle button - demonstrates reactive UI
          IconButton(
            icon: const Icon(Icons.brightness_6),
            tooltip: 'Toggle Theme',
            onPressed: widget.toggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.code),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WidgetTreeDemo(),
                ),
              );
            },
            tooltip: 'Widget Tree Demo',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back! 🌱',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Email: ${widget.user.email}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green.shade600,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Add Plant Section
            const Text(
              'Add New Plant',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _plantNameController,
              decoration: const InputDecoration(
                labelText: 'Plant Name',
                prefixIcon: Icon(Icons.eco),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: _plantTypeController,
              decoration: const InputDecoration(
                labelText: 'Plant Type',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: _addPlant,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              child: const Text('Add Plant'),
            ),
            
            const SizedBox(height: 24),
            
            // My Plants Section
            const Text(
              'My Plants',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Real-time plant list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestoreService.getUserPlants(widget.user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No plants added yet. Start by adding your first plant!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final plant = doc.data() as Map<String, dynamic>;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Icon(
                            Icons.eco,
                            color: Colors.green.shade600,
                            size: 30,
                          ),
                          title: Text(
                            plant['name'] ?? 'Unknown Plant',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Type: ${plant['type'] ?? 'Unknown'}\nAdded: ${DateTime.parse(plant['createdAt']).day}/${DateTime.parse(plant['createdAt']).month}/${DateTime.parse(plant['createdAt']).year}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await _firestoreService.deletePlantData(
                                widget.user.uid,
                                doc.id,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Plant deleted'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
