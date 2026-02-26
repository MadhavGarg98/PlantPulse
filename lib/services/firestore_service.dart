import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create: Add user data to Firestore
  Future<void> addUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).set(data);
    } catch (e) {
      print('Error adding user data: $e');
    }
  }

  // Read: Get user data
  Future<DocumentSnapshot> getUserData(String uid) async {
    try {
      return await _firestore.collection('users').doc(uid).get();
    } catch (e) {
      print('Error getting user data: $e');
      rethrow;
    }
  }

  // Update: Update user data
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      print('Error updating user data: $e');
    }
  }

  // Delete: Delete user data
  Future<void> deleteUserData(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      print('Error deleting user data: $e');
    }
  }

  // Create: Add plant data
  Future<void> addPlantData(String uid, Map<String, dynamic> plantData) async {
    try {
      await _firestore.collection('users').doc(uid).collection('plants').add(plantData);
    } catch (e) {
      print('Error adding plant data: $e');
    }
  }

  // Read: Get all plants for a user (real-time stream)
  Stream<QuerySnapshot> getUserPlants(String uid) {
    return _firestore.collection('users').doc(uid).collection('plants').snapshots();
  }

  // Read: Get all plants for a user (one-time)
  Future<List<DocumentSnapshot>> getPlantsData(String uid) async {
    try {
      final querySnapshot = await _firestore.collection('users').doc(uid).collection('plants').get();
      return querySnapshot.docs;
    } catch (e) {
      print('Error getting plants data: $e');
      return [];
    }
  }

  // Update: Update plant data
  Future<void> updatePlantData(String uid, String plantId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).collection('plants').doc(plantId).update(data);
    } catch (e) {
      print('Error updating plant data: $e');
    }
  }

  // Delete: Delete plant data
  Future<void> deletePlantData(String uid, String plantId) async {
    try {
      await _firestore.collection('users').doc(uid).collection('plants').doc(plantId).delete();
    } catch (e) {
      print('Error deleting plant data: $e');
    }
  }

  // Get all users (for admin purposes)
  Stream<QuerySnapshot> getAllUsers() {
    return _firestore.collection('users').snapshots();
  }
}
