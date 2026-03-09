import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

class FirebaseVerificationScreen extends StatefulWidget {
  const FirebaseVerificationScreen({super.key});

  @override
  State<FirebaseVerificationScreen> createState() => _FirebaseVerificationScreenState();
}

class _FirebaseVerificationScreenState extends State<FirebaseVerificationScreen> {
  bool _isInitialized = false;
  String _initializationStatus = 'Checking...';
  User? _currentUser;
  bool _firestoreConnected = false;

  @override
  void initState() {
    super.initState();
    _verifyFirebaseConnection();
  }

  Future<void> _verifyFirebaseConnection() async {
    try {
      // Check Firebase initialization
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      setState(() {
        _isInitialized = true;
        _initializationStatus = '✅ Firebase Initialized Successfully';
      });

      // Check Authentication
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        setState(() {
          _currentUser = user;
        });
      });

      // Check Firestore connection
      await FirebaseFirestore.instance.collection('test').limit(1).get();
      setState(() {
        _firestoreConnected = true;
      });

    } catch (e) {
      setState(() {
        _initializationStatus = '❌ Firebase Initialization Failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Verification'),
        backgroundColor: const Color(0xFF1B5E20),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(
              'Firebase Core',
              _initializationStatus,
              _isInitialized,
            ),
            const SizedBox(height: 16),
            _buildStatusCard(
              'Authentication',
              _currentUser != null 
                  ? '✅ User: ${_currentUser?.email ?? 'Anonymous'}' 
                  : '⚠️ No user logged in',
              _currentUser != null,
            ),
            const SizedBox(height: 16),
            _buildStatusCard(
              'Firestore Database',
              _firestoreConnected 
                  ? '✅ Firestore Connected' 
                  : '❌ Firestore Connection Failed',
              _firestoreConnected,
            ),
            const SizedBox(height: 24),
            _buildProjectInfo(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _verifyFirebaseConnection,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              child: const Text('Re-run Verification'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, String status, bool isSuccess) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              status,
              style: TextStyle(
                fontSize: 14,
                color: isSuccess ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Project Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Project ID: ${DefaultFirebaseOptions.currentPlatform.projectId}'),
            Text('App ID: ${DefaultFirebaseOptions.currentPlatform.appId}'),
            const Text('Package Name: com.example.plantpulse'),
          ],
        ),
      ),
    );
  }
}
