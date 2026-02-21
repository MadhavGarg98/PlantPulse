import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart';
import '../services/firestore_service.dart';

class EnhancedDashboardScreen extends StatefulWidget {
  final User user;
  
  const EnhancedDashboardScreen({super.key, required this.user});

  @override
  State<EnhancedDashboardScreen> createState() => _EnhancedDashboardScreenState();
}

class _EnhancedDashboardScreenState extends State<EnhancedDashboardScreen> 
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await _authService.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _showAddPlantModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddPlantModal(
        onAddPlant: (name, type) async {
          final plantData = {
            'name': name.trim(),
            'type': type.trim(),
            'createdAt': DateTime.now().toIso8601String(),
            'lastWatered': DateTime.now().toIso8601String(),
            'imageUrl': '', // Optional: can be added later
          };

          await _firestoreService.addPlantData(widget.user.uid, plantData);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    'Plant added successfully!',
                    style: GoogleFonts.inter(),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF1B5E20),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = widget.user.email ?? '';
    final userName = userEmail.split('@')[0].toUpperCase();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'PlantPulse',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1B5E20),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: _logout,
            color: const Color(0xFF6B7280),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              _buildWelcomeCard(userName),
              
              const SizedBox(height: 32),
              
              // Stats Section
              _buildStatsSection(),
              
              const SizedBox(height: 32),
              
              // My Plants Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Plants',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _buildPlantsGrid(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPlantModal,
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 4,
        icon: const Icon(Icons.add),
        label: Text(
          'Add Plant',
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(String userName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, $userName',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your plants are growing beautifully 🌿',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getUserPlants(widget.user.uid),
      builder: (context, snapshot) {
        int totalPlants = 0;
        int needsWater = 0;
        int recentlyAdded = 0;
        
        if (snapshot.hasData) {
          final plants = snapshot.data!.docs;
          totalPlants = plants.length;
          
          final now = DateTime.now();
          for (var plant in plants) {
            final plantData = plant.data() as Map<String, dynamic>;
            final createdAt = DateTime.parse(plantData['createdAt']);
            
            // Check if needs water (simplified logic - plants watered more than 3 days ago)
            final lastWatered = DateTime.parse(plantData['lastWatered']);
            if (now.difference(lastWatered).inDays > 3) {
              needsWater++;
            }
            
            // Check if recently added (added in last 7 days)
            if (now.difference(createdAt).inDays <= 7) {
              recentlyAdded++;
            }
          }
        }
        
        return Row(
          children: [
            Expanded(
              child: _buildStatCard('Total Plants', totalPlants.toString()),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard('Needs Water', needsWater.toString()),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard('Recently Added', recentlyAdded.toString()),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlantsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getUserPlants(widget.user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: GoogleFonts.inter(color: const Color(0xFFE53935)),
            ),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(
                    Icons.eco_outlined,
                    size: 40,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No plants yet',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add your first plant to get started',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          );
        }
        
        final plants = snapshot.data!.docs;
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 0.8,
          ),
          itemCount: plants.length,
          itemBuilder: (context, index) {
            final doc = plants[index];
            final plant = doc.data() as Map<String, dynamic>;
            
            return PlantCard(
              plant: plant,
              plantId: doc.id,
              onDelete: () async {
                await _firestoreService.deletePlantData(widget.user.uid, doc.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 10),
                        Text(
                          'Plant deleted',
                          style: GoogleFonts.inter(),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFF1B5E20),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class PlantCard extends StatelessWidget {
  final Map<String, dynamic> plant;
  final String plantId;
  final VoidCallback onDelete;

  const PlantCard({
    super.key,
    required this.plant,
    required this.plantId,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final plantName = plant['name'] ?? 'Unknown Plant';
    final plantType = plant['type'] ?? 'Unknown';
    final createdAt = DateTime.parse(plant['createdAt']);
    final formattedDate = '${createdAt.day}/${createdAt.month}/${createdAt.year}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plant Image Placeholder
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20).withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: const Icon(
                Icons.eco_outlined,
                size: 40,
                color: Color(0xFF1B5E20),
              ),
            ),
          ),
          
          // Plant Details
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plantName,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF111111),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plantType,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF6B7280),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  
                  // Delete Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: const Color(0xFFE53935),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935).withOpacity(0.1),
                        minimumSize: const Size(32, 32),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddPlantModal extends StatefulWidget {
  final Function(String name, String type) onAddPlant;

  const AddPlantModal({super.key, required this.onAddPlant});

  @override
  State<AddPlantModal> createState() => _AddPlantModalState();
}

class _AddPlantModalState extends State<AddPlantModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  void _addPlant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    await widget.onAddPlant(_nameController.text, _typeController.text);
    
    setState(() {
      _isLoading = false;
    });
    
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Add New Plant',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111111),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Plant Name',
                      prefixIcon: Icon(Icons.eco_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a plant name';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _typeController,
                    decoration: const InputDecoration(
                      labelText: 'Plant Type',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a plant type';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _addPlant,
                          child: _isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'Add Plant',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                                ),
                        ),
                      ),
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
}
