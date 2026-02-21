import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart';
import '../services/firestore_service.dart';

class PremiumDashboardScreen extends StatefulWidget {
  final User user;
  
  const PremiumDashboardScreen({super.key, required this.user});

  @override
  State<PremiumDashboardScreen> createState() => _PremiumDashboardScreenState();
}

class _PremiumDashboardScreenState extends State<PremiumDashboardScreen> 
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
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
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
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
      builder: (context) => PremiumAddPlantModal(
        onAddPlant: (name, type) async {
          final plantData = {
            'name': name.trim(),
            'type': type.trim(),
            'createdAt': DateTime.now().toIso8601String(),
            'lastWatered': DateTime.now().toIso8601String(),
            'imageUrl': '',
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
      body: Stack(
        children: [
          // Background decoration
          _buildBackground(),
          
          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      _buildHeader(),
                      
                      const SizedBox(height: 32),
                      
                      // Welcome Card
                      _buildWelcomeCard(userName),
                      
                      const SizedBox(height: 32),
                      
                      // Stats Section
                      _buildStatsSection(),
                      
                      const SizedBox(height: 32),
                      
                      // My Plants Section
                      Expanded(
                        child: _buildPlantsSection(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B5E20).withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _showAddPlantModal,
          backgroundColor: const Color(0xFF1B5E20),
          elevation: 0,
          icon: const Icon(Icons.add, size: 20),
          label: Text(
            'Add Plant',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Positioned(
          top: -200,
          right: -200,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1B5E20).withOpacity(0.02),
            ),
          ),
        ),
        Positioned(
          bottom: -300,
          left: -300,
          child: Container(
            width: 600,
            height: 600,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4CAF50).withOpacity(0.01),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PlantPulse',
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1B5E20),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your botanical sanctuary',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6B7280),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            onPressed: _logout,
            icon: const Icon(
              Icons.logout_outlined,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard(String userName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1B5E20).withOpacity(0.8),
            const Color(0xFF4CAF50).withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.wb_sunny_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          
          const SizedBox(height: 20),
          
          Text(
            'Welcome back, $userName',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Your plants are thriving beautifully today 🌿',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.9),
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
            
            final lastWatered = DateTime.parse(plantData['lastWatered']);
            if (now.difference(lastWatered).inDays > 3) {
              needsWater++;
            }
            
            if (now.difference(createdAt).inDays <= 7) {
              recentlyAdded++;
            }
          }
        }
        
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Plants',
                totalPlants.toString(),
                Icons.eco_outlined,
                const Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Needs Water',
                needsWater.toString(),
                Icons.water_drop_outlined,
                const Color(0xFF2196F3),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Recently Added',
                recentlyAdded.toString(),
                Icons.add_circle_outline,
                const Color(0xFF4CAF50),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111111),
            ),
          ),
          
          const SizedBox(height: 4),
          
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlantsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Plants',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111111),
              ),
            ),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/stateless_stateful_demo');
                },
                child: Text(
                  'View All',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        Expanded(
          child: _buildPlantsGrid(),
        ),
      ],
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
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.eco_outlined,
                    size: 50,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'No plants yet',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start your botanical journey by adding your first plant',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: const Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
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
            childAspectRatio: 0.75,
          ),
          itemCount: plants.length,
          itemBuilder: (context, index) {
            final doc = plants[index];
            final plant = doc.data() as Map<String, dynamic>;
            
            return PremiumPlantCard(
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

class PremiumPlantCard extends StatefulWidget {
  final Map<String, dynamic> plant;
  final String plantId;
  final VoidCallback onDelete;

  const PremiumPlantCard({
    super.key,
    required this.plant,
    required this.plantId,
    required this.onDelete,
  });

  @override
  State<PremiumPlantCard> createState() => _PremiumPlantCardState();
}

class _PremiumPlantCardState extends State<PremiumPlantCard> 
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plantName = widget.plant['name'] ?? 'Unknown Plant';
    final plantType = widget.plant['type'] ?? 'Unknown';
    final createdAt = DateTime.parse(widget.plant['createdAt']);
    final formattedDate = '${createdAt.day}/${createdAt.month}/${createdAt.year}';

    return GestureDetector(
      onTap: () {
        // TODO: Navigate to plant details
      },
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plant Image Section
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1B5E20).withOpacity(0.1),
                            const Color(0xFF4CAF50).withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.eco,
                                size: 40,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                          ),
                          
                          // Delete button
                          Positioned(
                            top: 12,
                            right: 12,
                            child: GestureDetector(
                              onTap: widget.onDelete,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Color(0xFFE53935),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Plant Details Section
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
                                  fontWeight: FontWeight.w600,
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
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF6B7280),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          
                          Text(
                            formattedDate,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class PremiumAddPlantModal extends StatefulWidget {
  final Function(String name, String type) onAddPlant;

  const PremiumAddPlantModal({super.key, required this.onAddPlant});

  @override
  State<PremiumAddPlantModal> createState() => _PremiumAddPlantModalState();
}

class _PremiumAddPlantModalState extends State<PremiumAddPlantModal> 
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  bool _isLoading = false;
  
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _slideController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _slideController.dispose();
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
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 40,
              offset: const Offset(0, -20),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 32,
            right: 32,
            top: 32,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1B5E20).withOpacity(0.1),
                          const Color(0xFF4CAF50).withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.eco,
                      size: 28,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  
                  const SizedBox(width: 20),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add New Plant',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111111),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Expand your botanical collection',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildPremiumField(
                      controller: _nameController,
                      label: 'Plant Name',
                      icon: Icons.eco_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a plant name';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    _buildPremiumField(
                      controller: _typeController,
                      label: 'Plant Type',
                      icon: Icons.category_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a plant type';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _addPlant,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B5E20),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
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
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
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
      ),
    );
  }

  Widget _buildPremiumField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF6B7280)),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE53935)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
