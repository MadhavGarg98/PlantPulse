import 'package:cloud_firestore/cloud_firestore.dart';

class PlantModel {
  final String? id;
  final String name;
  final String type;
  final String createdAt;
  final String lastWatered;
  final String? imageUrl;
  final String? notes;

  PlantModel({
    this.id,
    required this.name,
    required this.type,
    required this.createdAt,
    required this.lastWatered,
    this.imageUrl,
    this.notes,
  });

  // Create a PlantModel from Firestore document
  factory PlantModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PlantModel(
      id: doc.id,
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      createdAt: data['createdAt'] ?? '',
      lastWatered: data['lastWatered'] ?? '',
      imageUrl: data['imageUrl'],
      notes: data['notes'],
    );
  }

  // Convert PlantModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type,
      'createdAt': createdAt,
      'lastWatered': lastWatered,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (notes != null) 'notes': notes,
    };
  }

  // Create a copy with updated fields
  PlantModel copyWith({
    String? id,
    String? name,
    String? type,
    String? createdAt,
    String? lastWatered,
    String? imageUrl,
    String? notes,
  }) {
    return PlantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      lastWatered: lastWatered ?? this.lastWatered,
      imageUrl: imageUrl ?? this.imageUrl,
      notes: notes ?? this.notes,
    );
  }

  // Get formatted date strings
  String get formattedCreatedAt {
    try {
      final date = DateTime.parse(createdAt);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return createdAt;
    }
  }

  String get formattedLastWatered {
    try {
      final date = DateTime.parse(lastWatered);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return lastWatered;
    }
  }

  // Check if plant needs water (more than 3 days since last watered)
  bool get needsWater {
    try {
      final lastWateredDate = DateTime.parse(lastWatered);
      final now = DateTime.now();
      return now.difference(lastWateredDate).inDays > 3;
    } catch (e) {
      return false;
    }
  }

  // Check if plant was recently added (within last 7 days)
  bool get recentlyAdded {
    try {
      final createdDate = DateTime.parse(createdAt);
      final now = DateTime.now();
      return now.difference(createdDate).inDays <= 7;
    } catch (e) {
      return false;
    }
  }
}
