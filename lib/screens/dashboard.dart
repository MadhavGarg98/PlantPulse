import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/plant_model.dart';
import '../services/firebase_service.dart';
import '../services/firestore_service.dart';
import '../services/firebase_storage_service.dart';
import 'premium_login_screen.dart';

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

  late AnimationController _fadeController;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

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

  Future<void> _logout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const PremiumLoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await FirebaseStorageService.pickImage();
      if (image != null) {
        setState(() {
          _isUploading = true;
          _uploadProgress = 0.0;
        });

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image uploaded successfully! 🌿'),
              backgroundColor: Color(0xFF1B5E20),
            ),
          );
          
          // You can now use this downloadUrl to save to Firestore
          print('Uploaded image URL: $downloadUrl');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to upload image'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
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
                        if (snapshot.hasError) {
                          return _buildErrorState(snapshot.error.toString());
                        }
                        if (!snapshot.hasData || snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                          );
                        }
                        final plants = snapshot.data!.docs
                            .map((doc) => PlantModel.fromFirestore(doc))
                            .toList();
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

  Widget _buildErrorState(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 12),
          Text(
            'Failed to load plants',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/firestore-demo'),
            icon: const Icon(Icons.storage),
            tooltip: 'Firestore Demo',
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/image-upload', arguments: widget.user),
            icon: const Icon(Icons.photo_library),
            tooltip: 'Image Upload',
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    return FutureBuilder(
      future: _firestoreService.getUserData(widget.user.uid),
      builder: (context, snapshot) {
        String displayName = widget.user.email?.split('@').first ?? 'Plant Lover';
        if (snapshot.hasData) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null && data['name'] != null && (data['name'] as String).isNotEmpty) {
            displayName = data['name'] as String;
          }
        }
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF1B5E20),
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'P',
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  "Welcome back, $displayName",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
              ),
              IconButton(
                onPressed: _pickAndUploadImage,
                icon: const Icon(Icons.photo_camera),
                tooltip: 'Upload Plant Photo',
              ),
            ],
          ),
        );
      },
    );
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
                children: plantsNeedingCare.map((plant) => _buildCareCard(plant)).toList(),
              ),
      ],
    );
  }

  Widget _buildCareCard(PlantModel plant) {
    final imageUrl = plant.imageUrl != null && plant.imageUrl!.isNotEmpty
        ? plant.imageUrl!
        : _defaultPlantImageUrl;

    return Container(
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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("${plant.name} — update in plant detail 🌿"),
                  backgroundColor: const Color(0xFF1B5E20),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
            child: const Text("Water"),
          ),
        ],
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
                    Icon(Icons.eco_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      "No plants yet",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Add plants from the profile screen",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey[500],
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
                  final plant = plants[index];
                  final imageUrl = plant.imageUrl != null && plant.imageUrl!.isNotEmpty
                      ? plant.imageUrl!
                      : _defaultPlantImageUrl;

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(22),
                            ),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.eco, size: 48),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Text(
                                plant.name,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                plant.type,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
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
