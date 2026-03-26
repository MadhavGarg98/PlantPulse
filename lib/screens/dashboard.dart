import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/plant_model.dart';
import '../services/firebase_service.dart';
import '../services/firestore_service.dart';
import '../services/firebase_storage_service.dart';
import '../services/watering_schedule_service.dart';
import 'premium_login_screen.dart';
import 'profile_screen.dart';
import 'notification_screen.dart';
import 'weather_screen.dart';
import 'plant_schedule_screen.dart';
import 'watering_analytics_screen.dart';
import 'dart:math';
import 'dart:ui' as ui;

class DashboardScreen extends StatefulWidget {
  final User user;

  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final WateringScheduleService _scheduleService = WateringScheduleService();

  late AnimationController _fadeController;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  bool _showAddPlantDialog = false;
  
  // Additional features
  DateTime _lastRefresh = DateTime.now();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  static const String _defaultPlantImageUrl =
      'https://images.unsplash.com/photo-1416879595882-3373a0480b5b';

  Future<void> _showWeather() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WeatherScreen()),
    );
  }

  Future<void> _showNotifications() async {
    // Show notifications page or dialog
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationScreen()),
    );
  }

  Future<void> _showWateringAnalytics() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WateringAnalyticsScreen()),
    );
  }

  Future<void> _openPlantSchedule(PlantModel plant) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PlantScheduleScreen(plant: plant)),
    );
    
    // Refresh the dashboard if schedule was updated
    if (result == true) {
      setState(() {
        _lastRefresh = DateTime.now();
      });
    }
  }

  Future<void> _logout() async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Logout',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.inter(),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const PremiumLoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _addSamplePlants() async {
    try {
      final samplePlants = [
        PlantModel(
          id: 'sample_1',
          name: 'Monstera Deliciosa',
          type: 'Tropical Plant',
          createdAt: DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          lastWatered: DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          imageUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b',
          notes: 'Loves bright, indirect light',
        ),
        PlantModel(
          id: 'sample_2',
          name: 'Snake Plant',
          type: 'Succulent',
          createdAt: DateTime.now().subtract(const Duration(days: 60)).toIso8601String(),
          lastWatered: DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
          imageUrl: 'https://images.unsplash.com/photo-1527248403834-dcf5afe3383d',
          notes: 'Very low maintenance',
        ),
        PlantModel(
          id: 'sample_3',
          name: 'Pothos',
          type: 'Vining Plant',
          createdAt: DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
          lastWatered: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          imageUrl: 'https://images.unsplash.com/photo-1578616066572-a408562b1c9f',
          notes: 'Great for beginners',
        ),
      ];

      for (final plant in samplePlants) {
        await _firestoreService.addPlantData(widget.user.uid, plant.toFirestore());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sample plants added! 🌱'),
          backgroundColor: Color(0xFF1B5E20),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding sample plants: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Choose Image Source', style: GoogleFonts.inter()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.camera),
              child: Text('Camera', style: GoogleFonts.inter()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.gallery),
              child: Text('Gallery', style: GoogleFonts.inter()),
            ),
          ],
        ),
      );

      if (source == null) return;

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      
      if (image != null) {
        setState(() {
          _isUploading = true;
          _uploadProgress = 0.0;
        });

        try {
          // Show upload progress
          FirebaseStorageService.getUploadProgress(image).listen((snapshot) {
            setState(() {
              _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
            });
          });

          // Upload image
          final String? downloadUrl = await FirebaseStorageService.uploadImage(
            image,
            customFileName: 'plant_${DateTime.now().millisecondsSinceEpoch}',
          );

          setState(() {
            _isUploading = false;
          });

          if (downloadUrl != null) {
            // Create a new plant with the uploaded image
            final PlantModel newPlant = PlantModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: 'Plant ${Random().nextInt(1000)}',
              type: 'Uploaded Plant',
              imageUrl: downloadUrl,
              createdAt: DateTime.now().toIso8601String(),
              lastWatered: DateTime.now().toIso8601String(),
              notes: 'Uploaded from camera',
            );

            await _firestoreService.addPlantData(widget.user.uid, newPlant.toFirestore());

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Plant added successfully! 🌿'),
                backgroundColor: Color(0xFF1B5E20),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload image'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          setState(() {
            _isUploading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<PlantModel> _getSamplePlants() {
    return [
      PlantModel(
        id: 'sample_1',
        name: 'Monstera Deliciosa',
        type: 'Tropical Plant',
        imageUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b',
        createdAt: DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        lastWatered: DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        notes: 'Loves bright, indirect light',
      ),
      PlantModel(
        id: 'sample_2',
        name: 'Snake Plant',
        type: 'Succulent',
        imageUrl: 'https://images.unsplash.com/photo-1527248403834-dcf5afe3383d',
        createdAt: DateTime.now().subtract(const Duration(days: 60)).toIso8601String(),
        lastWatered: DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
        notes: 'Very low maintenance',
      ),
      PlantModel(
        id: 'sample_3',
        name: 'Pothos',
        type: 'Vining Plant',
        imageUrl: 'https://images.unsplash.com/photo-1578616066572-a408562b1c9f',
        createdAt: DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
        lastWatered: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        notes: 'Great for beginners',
      ),
      PlantModel(
        id: 'sample_4',
        name: 'Fiddle Leaf Fig',
        type: 'Tree',
        imageUrl: 'https://images.unsplash.com/photo-1485955900006-10f4d324d411',
        createdAt: DateTime.now().subtract(const Duration(days: 45)).toIso8601String(),
        lastWatered: DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
        notes: 'Needs bright, consistent light',
      ),
      PlantModel(
        id: 'sample_5',
        name: 'Peace Lily',
        type: 'Flowering Plant',
        imageUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b',
        createdAt: DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
        lastWatered: DateTime.now().subtract(const Duration(days: 4)).toIso8601String(),
        notes: 'Droops when thirsty',
      ),
    ];
  }

  Future<void> _refreshData() async {
    setState(() {
      _lastRefresh = DateTime.now();
    });
    
    // Simulate refresh delay
    await Future.delayed(const Duration(milliseconds: 1000));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dashboard refreshed! 🌿'),
        backgroundColor: const Color(0xFF1B5E20),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showAddPlantOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add New Plant',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: Color(0xFF1B5E20)),
              title: Text('Take Photo', style: GoogleFonts.inter()),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF1B5E20)),
              title: Text('Choose from Gallery', style: GoogleFonts.inter()),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.eco, color: Color(0xFF1B5E20)),
              title: Text('Add Sample Plants', style: GoogleFonts.inter()),
              onTap: () {
                Navigator.pop(context);
                _addSamplePlants();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8F7),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.eco,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'PlantPulse',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1B5E20),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showWeather,
            icon: const Icon(
              Icons.cloud_outlined,
              color: Color(0xFF1B5E20),
            ),
            tooltip: 'Weather & Care',
          ),
          IconButton(
            onPressed: _showWateringAnalytics,
            icon: const Icon(
              Icons.analytics_outlined,
              color: Color(0xFF1B5E20),
            ),
            tooltip: 'Watering Analytics',
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfileScreen(user: widget.user)),
            ),
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipOval(
                child: widget.user.photoURL != null
                    ? Image.network(
                        widget.user.photoURL!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: 0,
          onTap: (index) {
            if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen(user: widget.user)),
              );
            } else if (index == 2) {
              _showNotifications();
            }
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, color: Color(0xFF1B5E20)),
              activeIcon: Icon(Icons.home, color: Color(0xFF1B5E20)),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, color: Color(0xFF1B5E20)),
              activeIcon: Icon(Icons.person, color: Color(0xFF1B5E20)),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined, color: Color(0xFF1B5E20)),
              activeIcon: Icon(Icons.notifications, color: Color(0xFF1B5E20)),
              label: 'Notifications',
            ),
          ],
        ),
      ),
      body: FadeTransition(
        opacity: _fadeController,
        child: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreeting(),
                    const SizedBox(height: 28),
                    StreamBuilder(
                      stream: _firestoreService.getUserPlants(widget.user.uid),
                      builder: (context, snapshot) {
                        List<PlantModel> plants = [];
                        
                        // Handle different states
                        if (snapshot.hasError) {
                          // If there's a permission error or any other error, show sample plants
                          print('Firestore error: ${snapshot.error}');
                          plants = _getSamplePlants();
                        } else if (!snapshot.hasData || snapshot.connectionState == ConnectionState.waiting) {
                          // Show loading indicator
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                          );
                        } else {
                          // Parse real data
                          plants = snapshot.data!.docs
                              .map((doc) => PlantModel.fromFirestore(doc))
                              .toList();
                          
                          // If no plants exist, show sample plants
                          if (plants.isEmpty) {
                            plants = _getSamplePlants();
                          }
                        }
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPlantHealth(plants),
                            const SizedBox(height: 28),
                            _buildTodaysCare(plants),
                            const SizedBox(height: 28),
                            _buildMyPlants(plants),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            if (_isUploading)
              _buildUploadProgressOverlay(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPlantOptions,
        backgroundColor: const Color(0xFF1B5E20),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Plant',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildUploadProgressOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: Color(0xFF1B5E20),
              ),
              const SizedBox(height: 16),
              Text(
                'Uploading image...',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1B5E20)),
              ),
              const SizedBox(height: 8),
              Text(
                '${(_uploadProgress * 100).toInt()}%',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    return FutureBuilder(
      future: _firestoreService.getUserData(widget.user.uid),
      builder: (context, snapshot) {
        // Get current day name
        final now = DateTime.now();
        final dayName = _getDayName(now.weekday);
        
        // Extract proper name from email or use Firestore name
        String displayName = _extractDisplayName(widget.user.email);
        if (snapshot.hasData) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null && data['name'] != null && (data['name'] as String).isNotEmpty) {
            displayName = data['name'] as String;
          }
        }
        
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1B5E20),
                const Color(0xFF2E7D32),
                const Color(0xFF4CAF50),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B5E20).withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
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
                          dayName,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Welcome back, $displayName',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.eco,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Your plants are thriving! 🌱',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return 'Today';
    }
  }

  String _extractDisplayName(String? email) {
    if (email == null || email.isEmpty) return 'Plant Lover';
    
    // Extract name before @ and capitalize properly
    final localPart = email.split('@').first;
    
    // Handle common patterns
    if (localPart.contains('.') || localPart.contains('_')) {
      final parts = localPart.split(RegExp(r'[._]'));
      final name = parts.map((part) => 
        part.isNotEmpty ? part[0].toUpperCase() + part.substring(1).toLowerCase() : ''
      ).join(' ');
      return name;
    }
    
    // For simple names like "madhavgarg3300", extract the name part
    final nameMatch = RegExp(r'([a-zA-Z]+)').firstMatch(localPart);
    if (nameMatch != null) {
      final name = nameMatch.group(1)!;
      return name[0].toUpperCase() + name.substring(1).toLowerCase();
    }
    
    return localPart[0].toUpperCase() + localPart.substring(1).toLowerCase();
  }

  Widget _buildPlantHealth(List<PlantModel> plants) {
    final wateredCount = plants.where((p) => !p.needsWater).length;
    final needsCareCount = plants.where((p) => p.needsWater).length;
    final healthyCount = plants.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Plant Health",
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildHealthCard("Watered", wateredCount)),
            const SizedBox(width: 12),
            Expanded(child: _buildHealthCard("Total", healthyCount)),
            const SizedBox(width: 12),
            Expanded(child: _buildHealthCard("Needs Care", needsCareCount)),
          ],
        ),
      ],
    );
  }

  Widget _buildHealthCard(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysCare(List<PlantModel> plants) {
    final plantsNeedingCare = plants.where((p) => p.needsWater).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Care (${plantsNeedingCare.length})",
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        plantsNeedingCare.isEmpty
            ? Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF1B5E20), size: 36),
                    const SizedBox(width: 16),
                    Text(
                      "All plants are watered! 🌿",
                      style: GoogleFonts.inter(fontSize: 16),
                    ),
                  ],
                ),
              )
            : Column(
                children: plantsNeedingCare.map((plant) {
                  final plantImageUrl = plant.imageUrl != null && plant.imageUrl!.isNotEmpty
                      ? plant.imageUrl!
                      : _defaultPlantImageUrl;

                  return Dismissible(
                    key: Key('care_${plant.id ?? ''}_${DateTime.now().millisecondsSinceEpoch}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    onDismissed: (direction) {
                      _deletePlant(plant);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              plantImageUrl,
                              width: 65,
                              height: 65,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 65,
                                height: 65,
                                color: Colors.grey[300],
                                child: const Icon(Icons.eco, size: 32),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  plant.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  plant.type,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _waterPlant(plant),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                            child: const Text("Water"),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
      ],
    );
  }

  Widget _buildCareCard(PlantModel plant) {
    final imageUrl = plant.imageUrl != null && plant.imageUrl!.isNotEmpty
        ? plant.imageUrl!
        : _defaultPlantImageUrl;

    return Dismissible(
      key: Key('care_${plant.id ?? ''}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 24,
        ),
      ),
      onDismissed: (direction) {
        _deletePlant(plant);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                imageUrl,
                width: 65,
                height: 65,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 65,
                  height: 65,
                  color: Colors.grey[300],
                  child: const Icon(Icons.eco, size: 32),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    plant.type,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _waterPlant(plant),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
              child: const Text("Water"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyPlants(List<PlantModel> plants) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "My Plants",
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        plants.isEmpty
            ? Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  children: [
                    Icon(Icons.eco_outlined, size: 64, color: Color(0xFF1B5E20)),
                    const SizedBox(height: 12),
                    Text(
                      "Your Plant Collection",
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Beautiful plants to inspire your journey",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            : GridView.builder(
                itemCount: plants.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemBuilder: (context, index) {
                  return Dismissible(
                    key: Key('plant_${plants[index].id ?? ''}_${DateTime.now().millisecondsSinceEpoch}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    onDismissed: (direction) {
                      _deletePlant(plants[index]);
                    },
                    child: _buildPlantCard(plants[index]),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildPlantCard(PlantModel plant) {
    final imageUrl = plant.imageUrl != null && plant.imageUrl!.isNotEmpty
        ? plant.imageUrl!
        : _defaultPlantImageUrl;
    
    final daysSinceWatered = _getDaysSinceWatered(plant.lastWatered);
    final needsWater = plant.needsWater;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                  onError: (error, stackTrace) {},
                ),
              ),
              child: Stack(
                children: [
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.4),
                        ],
                      ),
                    ),
                  ),
                  // Water status indicator
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: needsWater ? Colors.orange : Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.water_drop,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            needsWater ? 'Water' : 'OK',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Info section
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1B5E20),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plant.type,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 12,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$daysSinceWatered days ago',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getDaysSinceWatered(String lastWatered) {
    try {
      final lastWateredDate = DateTime.parse(lastWatered);
      return DateTime.now().difference(lastWateredDate).inDays;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _waterPlant(PlantModel plant) async {
    try {
      // Update the lastWatered timestamp
      final updatedPlant = plant.copyWith(
        lastWatered: DateTime.now().toIso8601String(),
      );
      
      // Update in Firestore
      await _firestoreService.updatePlantData(
        widget.user.uid, 
        plant.id ?? '', 
        updatedPlant.toFirestore()
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${plant.name} watered successfully! 💧"),
          backgroundColor: const Color(0xFF1B5E20),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to water plant: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deletePlant(PlantModel plant) async {
    try {
      // Show confirmation dialog
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Delete Plant',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Are you sure you want to delete "${plant.name}"? This action cannot be undone.',
            style: GoogleFonts.inter(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.grey[600]),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Delete',
                style: GoogleFonts.inter(color: Colors.red),
              ),
            ),
          ],
        ),
      );

      if (shouldDelete == true) {
        // Delete from Firestore
        await _firestoreService.deletePlantData(widget.user.uid, plant.id ?? '');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${plant.name} deleted successfully! 🌱"),
            backgroundColor: const Color(0xFF1B5E20),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to delete plant: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Floating Action Button for Image Upload
class UploadFab extends StatelessWidget {
  final VoidCallback onPressed;

  const UploadFab({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: const Color(0xFF1B5E20),
      child: const Icon(Icons.add_a_photo, color: Colors.white),
    );
  }
}
