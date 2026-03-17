import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_service.dart';
import '../services/firestore_service.dart';
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

  List<Plant> _plants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _fadeController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _fadeController.forward();

    _loadDemoData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // -------------------------
  // DEMO DATA
  // -------------------------
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
        id: '2',
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

  // -------------------------
  // CALCULATIONS
  // -------------------------
  int get _wateredCount => _plants
      .where((p) =>
          p.lastWatered.isAfter(DateTime.now().subtract(const Duration(days: 2))))
      .length;

  int get _healthyCount => _plants.where((p) => p.isHealthy).length;

  int get _needsCareCount => _plants.length - _wateredCount;

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
    await _authService.signOut();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const PremiumLoginScreen()),
        (route) => false,
      );
    }
  }

  // -------------------------
  // MAIN UI
  // -------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      body: FadeTransition(
        opacity: _fadeController,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreeting(),
                const SizedBox(height: 28),
                _buildPlantHealth(),
                const SizedBox(height: 28),
                _buildTodaysCare(),
                const SizedBox(height: 28),
                _buildMyPlants(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------
  // GREETING
  // -------------------------
  Widget _buildGreeting() {
    final userName = widget.user.email?.split('@').first ?? 'Plant Lover';

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
              userName[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              "Welcome back, $userName",
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
            onPressed: () => Navigator.pushNamed(context, '/firestore-demo'),
            icon: const Icon(Icons.storage),
            tooltip: 'Firestore Demo',
          ),
        ],
      ),
    );
  }

  // -------------------------
  // HEALTH CARDS
  // -------------------------
  Widget _buildPlantHealth() {
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
            Expanded(child: _buildHealthCard("Watered", _wateredCount)),
            const SizedBox(width: 12),
            Expanded(child: _buildHealthCard("Healthy", _healthyCount)),
            const SizedBox(width: 12),
            Expanded(child: _buildHealthCard("Needs Care", _needsCareCount)),
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
          )
        ],
      ),
    );
  }

  // -------------------------
  // TODAY CARE
  // -------------------------
  Widget _buildTodaysCare() {
    final remaining = _plantsNeedingCare.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Care ($remaining)",
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: _plants.map((plant) => _buildCareCard(plant)).toList(),
        ),
      ],
    );
  }

  Widget _buildCareCard(Plant plant) {
    final isWateredToday = plant.lastWatered
        .isAfter(DateTime.now().subtract(const Duration(days: 2)));

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
              plant.imageUrl,
              width: 65,
              height: 65,
              fit: BoxFit.cover,
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
                  plant.scientificName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: isWateredToday ? null : () => _waterPlant(plant),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
            ),
            child: Text(isWateredToday ? "Done" : "Water"),
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
        Text(
          "My Plants",
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          itemCount: _plants.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemBuilder: (context, index) {
            final plant = _plants[index];

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
                        Text(
                          plant.name,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          plant.scientificName,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        )
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

// -------------------------
// PLANT MODEL
// -------------------------
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