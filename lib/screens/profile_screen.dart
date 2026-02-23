import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../services/firestore_service.dart';
import 'premium_login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final User user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _logout() async {
    await _authService.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const PremiumLoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1B5E20),
        title: Text(
          "My Profile",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),

            /// Profile Image
            CircleAvatar(
              radius: 55,
              backgroundColor:
                  const Color(0xFF1B5E20).withValues(alpha: 0.1),
              backgroundImage: user.photoURL != null
                  ? NetworkImage(user.photoURL!)
                  : null,
              child: user.photoURL == null
                  ? const Icon(
                      Icons.person,
                      size: 55,
                      color: Color(0xFF1B5E20),
                    )
                  : null,
            ),

            const SizedBox(height: 20),

            /// Name
            Text(
              user.displayName ?? "PlantPulse User",
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1B5E20),
              ),
            ),

            const SizedBox(height: 6),

            /// Email
            Text(
              user.email ?? "",
              style: GoogleFonts.inter(
                fontSize: 15,
                color: Colors.grey[700],
              ),
            ),

            const SizedBox(height: 40),

            /// Plant Count Card
            StreamBuilder(
              stream: _firestoreService.getUserPlants(user.uid),
              builder: (context, snapshot) {
                int plantCount = 0;

                if (snapshot.hasData) {
                  plantCount = snapshot.data!.docs.length;
                }

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 25, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.eco,
                        color: Color(0xFF1B5E20),
                        size: 36,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "$plantCount Plants",
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "You're growing beautifully 🌿",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const Spacer(),

            /// Logout Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: Text(
                  "Logout",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}