import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart';
import '../services/firestore_service.dart';
import 'profile_screen.dart';
import 'home_screen.dart';
import 'premium_login_screen.dart';
import 'scrollable_views.dart';

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
  late AnimationController _progressController;

  List<Plant> _plants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDemoData(); // You can switch back to Firestore later

    _fadeController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _progressController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _progressController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  // DEMO DATA
  void _loadDemoData() {
    _plants = [
      Plant(
        id: '1',
        name: 'Monstera',
        scientificName: 'Monstera Deliciosa',
        lastWatered: DateTime.now().subtract(const Duration(days: 3)),
        imageUrl:
            'https://images.unsplash.com/photo-1416879595882-3373a0480b5b',
        isHealthy: true,
      ),
      Plant(
        id: '3',
        name: 'Snake Plant',
        scientificName: 'Sansevieria',
        lastWatered: DateTime.now().subtract(const Duration(days: 5)),
        imageUrl:
            'https://images.unsplash.com/photo-1485955900006-10f4d324d411',
        isHealthy: false,
      ),
    ];

    _isLoading = false;
    setState(() {});
  }

  // CALCULATIONS
  int get _wateredCount => _plants
      .where((p) =>
          p.lastWatered.isAfter(DateTime.now().subtract(const Duration(days: 2))))
      .length;

  int get _healthyCount => _plants.where((p) => p.isHealthy).length;

  int get _needsCareCount =>
      _plants.length - _wateredCount;

  List<Plant> get _plantsNeedingCare => _plants
      .where((p) =>
          !p.lastWatered.isAfter(DateTime.now().subtract(const Duration(days: 2))))
      .toList();

  void _waterPlant(Plant plant) {
    setState(() {
      plant.lastWatered = DateTime.now();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${plant.name} watered 🌿"),
        backgroundColor: const Color(0xFF1B5E20),
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const PremiumLoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      body: FadeTransition(
        opacity: _fadeController,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreeting(),
                const SizedBox(height: 32),
                _buildPlantHealth(),
                const SizedBox(height: 32),
                _buildTodaysCare(),
                const SizedBox(height: 32),
                _buildMyPlants(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------
  // GREETING SECTION
  // -------------------------
  Widget _buildGreeting() {
    final now = DateTime.now();
    final hour = now.hour;
    final userName = widget.user.email?.split('@').first ?? 'Plant Lover';
    
    // Time-based greeting
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }
    
    // Format date
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final weekday = weekdays[now.weekday - 1];
    final month = months[now.month - 1];
    final day = now.day;
    
    // Time-based message
    String message;
    if (hour < 12) {
      message = 'Your plants are ready for a new day 🌱';
    } else if (hour < 17) {
      message = 'Your plants are thriving in the afternoon 🌿';
    } else {
      message = 'Your garden rests peacefully tonight 🌿';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "$weekday, $month $day",
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            IconButton(
              onPressed: _logout,
              icon: const Icon(Icons.logout, size: 20),
              style: IconButton.styleFrom(
                foregroundColor: Colors.grey[600],
                padding: EdgeInsets.zero,
                minimumSize: Size(40, 40),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "$greeting, ${userName[0].toUpperCase() + userName.substring(1).toLowerCase()}",
          style: GoogleFonts.inter(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // -------------------------
  // PLANT HEALTH
  // -------------------------
  Widget _buildPlantHealth() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Plant Health",
          style: GoogleFonts.inter(
              fontSize: 18, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMetricCircle(_wateredCount, "Watered", const Color(0xFF1B5E20)),
            _buildMetricCircle(_healthyCount, "Healthy", const Color(0xFF4CAF50)),
            _buildMetricCircle(_needsCareCount, "Needs Care", Colors.orange),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCircle(int value, String label, Color color) {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        return Column(
          children: [
            SizedBox(
              width: 70,
              height: 70,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _progressController.value,
                    strokeWidth: 6,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                  Text(
                    value.toString(),
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12, color: Colors.grey[600])),
          ],
        );
      },
    );
  }

  // -------------------------
  // TODAY CARE
  // -------------------------
  Widget _buildTodaysCare() {
  final allPlants = _plants;
  final remaining = _plantsNeedingCare.length;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(
            "Today's Care",
            style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "$remaining remaining",
              style: GoogleFonts.inter(fontSize: 12),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Column(
        children: allPlants
            .map((plant) => _buildCareCard(plant))
            .toList(),
      ),
    ],
  );
}

  Widget _buildSuccessState() {
    final hour = DateTime.now().hour;
    String message;
    String subMessage;
    
    if (hour < 12) {
      message = "All caught up";
      subMessage = "Your plants are happy this morning 🌱";
    } else if (hour < 17) {
      message = "All caught up";
      subMessage = "Your plants are thriving this afternoon 🌿";
    } else {
      message = "All caught up";
      subMessage = "Your plants are resting well tonight 🌿";
    }
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.check_circle,
                color: Color(0xFF1B5E20), size: 40),
            const SizedBox(height: 12),
            Text(message,
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(subMessage,
                style: GoogleFonts.inter(
                    fontSize: 13, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildCareCard(Plant plant) {
  final isWateredToday = plant.lastWatered
      .isAfter(DateTime.now().subtract(const Duration(days: 2)));

  return AnimatedContainer(
    duration: const Duration(milliseconds: 400),
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isWateredToday
          ? const Color(0xFFE8F5E9)
          : Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            plant.imageUrl,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plant.name,
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
              Text(
                plant.scientificName,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: isWateredToday
              ? null
              : () => _waterPlant(plant),
          style: ElevatedButton.styleFrom(
            backgroundColor: isWateredToday
                ? Colors.grey
                : const Color(0xFF1B5E20),
          ),
          child: Text(
            isWateredToday ? "Watered" : "Water",
          ),
        )
      ],
    ),
  );
}

  // -------------------------
  // MY PLANTS GRID
  // -------------------------
  Widget _buildMyPlants() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "My Plants",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ScrollableViews(),
                  ),
                );
              },
              child: Text(
                "See All",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF1B5E20),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          itemCount: _plants.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 0.8,
          ),
          itemBuilder: (context, index) {
            final plant = _plants[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24)),
                      child: Image.network(
                        plant.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text(plant.name,
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        Text(plant.scientificName,
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[600])),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        )
      ],
    );
  }
}

// MODEL
class Plant {
  final String id;
  final String name;
  final String scientificName;
  DateTime lastWatered;
  final String imageUrl;
  final bool isHealthy;

  Plant({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.lastWatered,
    required this.imageUrl,
    required this.isHealthy,
  });
}