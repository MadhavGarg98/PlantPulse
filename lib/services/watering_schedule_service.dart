import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import '../models/plant_model.dart';
import '../services/weather_service.dart';
import 'notification_service.dart';

class WateringSchedule {
  final String plantId;
  final String plantName;
  final int frequencyDays; // How often to water (in days)
  final TimeOfDay preferredTime;
  final bool weatherAware;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastWatered;
  final DateTime? nextWatering;

  WateringSchedule({
    required this.plantId,
    required this.plantName,
    required this.frequencyDays,
    required this.preferredTime,
    this.weatherAware = true,
    this.isActive = true,
    required this.createdAt,
    this.lastWatered,
    this.nextWatering,
  });

  Map<String, dynamic> toMap() {
    return {
      'plantId': plantId,
      'plantName': plantName,
      'frequencyDays': frequencyDays,
      'preferredTime': '${preferredTime.hour}:${preferredTime.minute}',
      'weatherAware': weatherAware,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastWatered': lastWatered?.toIso8601String(),
      'nextWatering': nextWatering?.toIso8601String(),
    };
  }

  factory WateringSchedule.fromMap(Map<String, dynamic> map) {
    final timeStr = map['preferredTime'] as String? ?? '09:00';
    final timeParts = timeStr.split(':');
    final preferredTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    return WateringSchedule(
      plantId: map['plantId'] as String,
      plantName: map['plantName'] as String,
      frequencyDays: map['frequencyDays'] as int,
      preferredTime: preferredTime,
      weatherAware: map['weatherAware'] as bool? ?? true,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastWatered: map['lastWatered'] != null 
          ? DateTime.parse(map['lastWatered'] as String) 
          : null,
      nextWatering: map['nextWatering'] != null 
          ? DateTime.parse(map['nextWatering'] as String) 
          : null,
    );
  }

  WateringSchedule copyWith({
    String? plantId,
    String? plantName,
    int? frequencyDays,
    TimeOfDay? preferredTime,
    bool? weatherAware,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastWatered,
    DateTime? nextWatering,
  }) {
    return WateringSchedule(
      plantId: plantId ?? this.plantId,
      plantName: plantName ?? this.plantName,
      frequencyDays: frequencyDays ?? this.frequencyDays,
      preferredTime: preferredTime ?? this.preferredTime,
      weatherAware: weatherAware ?? this.weatherAware,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastWatered: lastWatered ?? this.lastWatered,
      nextWatering: nextWatering ?? this.nextWatering,
    );
  }
}

class WateringHistory {
  final String plantId;
  final String plantName;
  final DateTime wateredAt;
  final String? notes;
  final bool wasScheduled;
  final Map<String, dynamic>? weatherData;

  WateringHistory({
    required this.plantId,
    required this.plantName,
    required this.wateredAt,
    this.notes,
    this.wasScheduled = false,
    this.weatherData,
  });

  Map<String, dynamic> toMap() {
    return {
      'plantId': plantId,
      'plantName': plantName,
      'wateredAt': wateredAt.toIso8601String(),
      'notes': notes,
      'wasScheduled': wasScheduled,
      'weatherData': weatherData,
    };
  }

  factory WateringHistory.fromMap(Map<String, dynamic> map) {
    return WateringHistory(
      plantId: map['plantId'] as String,
      plantName: map['plantName'] as String,
      wateredAt: DateTime.parse(map['wateredAt'] as String),
      notes: map['notes'] as String?,
      wasScheduled: map['wasScheduled'] as bool? ?? false,
      weatherData: map['weatherData'] as Map<String, dynamic>?,
    );
  }
}

class WateringScheduleService {
  static final WateringScheduleService _instance = WateringScheduleService._internal();
  factory WateringScheduleService() => _instance;
  WateringScheduleService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Get all schedules for current user
  Future<List<WateringSchedule>> getUserSchedules(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('wateringSchedules')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt')
          .get();

      return snapshot.docs
          .map((doc) => WateringSchedule.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting user schedules: $e');
      return [];
    }
  }

  // Create or update watering schedule
  Future<bool> saveWateringSchedule(String userId, WateringSchedule schedule) async {
    try {
      // Calculate next watering date
      final nextWatering = _calculateNextWatering(schedule);
      final updatedSchedule = schedule.copyWith(nextWatering: nextWatering);

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('wateringSchedules')
          .doc(schedule.plantId)
          .set(updatedSchedule.toMap());

      // Schedule notification
      await _scheduleWateringNotification(userId, updatedSchedule);

      return true;
    } catch (e) {
      print('Error saving watering schedule: $e');
      return false;
    }
  }

  // Delete watering schedule
  Future<bool> deleteWateringSchedule(String userId, String plantId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('wateringSchedules')
          .doc(plantId)
          .delete();

      // Cancel notification
      await _cancelWateringNotification(plantId);

      return true;
    } catch (e) {
      print('Error deleting watering schedule: $e');
      return false;
    }
  }

  // Mark plant as watered
  Future<bool> markAsWatered(String userId, String plantId, {String? notes}) async {
    try {
      final scheduleDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('wateringSchedules')
          .doc(plantId)
          .get();

      if (!scheduleDoc.exists) return false;

      final schedule = WateringSchedule.fromMap(scheduleDoc.data()!);
      final now = DateTime.now();

      // Update schedule
      final updatedSchedule = schedule.copyWith(
        lastWatered: now,
        nextWatering: _calculateNextWatering(schedule.copyWith(lastWatered: now)),
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('wateringSchedules')
          .doc(plantId)
          .update(updatedSchedule.toMap());

      // Add to history
      final weatherData = await WeatherService.getCurrentWeather();
      final history = WateringHistory(
        plantId: plantId,
        plantName: schedule.plantName,
        wateredAt: now,
        notes: notes,
        wasScheduled: true,
        weatherData: weatherData['success'] == true ? weatherData['data'] : null,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('wateringHistory')
          .add(history.toMap());

      // Reschedule next notification
      await _scheduleWateringNotification(userId, updatedSchedule);

      return true;
    } catch (e) {
      print('Error marking as watered: $e');
      return false;
    }
  }

  // Get watering history
  Future<List<WateringHistory>> getWateringHistory(String userId, {int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('wateringHistory')
          .orderBy('wateredAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => WateringHistory.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting watering history: $e');
      return [];
    }
  }

  // Get watering analytics
  Future<Map<String, dynamic>> getWateringAnalytics(String userId) async {
    try {
      final history = await getWateringHistory(userId, limit: 100);
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      final recentHistory = history.where((h) => h.wateredAt.isAfter(thirtyDaysAgo)).toList();
      
      // Calculate statistics
      final totalWaterings = recentHistory.length;
      final plantsWatered = recentHistory.map((h) => h.plantId).toSet().length;
      final averagePerDay = totalWaterings / 30;
      
      // Most watered plant
      final plantCounts = <String, int>{};
      for (final h in recentHistory) {
        plantCounts[h.plantName] = (plantCounts[h.plantName] ?? 0) + 1;
      }
      final mostWateredPlant = plantCounts.isNotEmpty 
          ? plantCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key 
          : 'None';

      // Weather-based insights
      final weatherBasedWaterings = recentHistory.where((h) => h.wasScheduled).length;
      final weatherBasedPercentage = totalWaterings > 0 
          ? (weatherBasedWaterings / totalWaterings * 100).round() 
          : 0;

      return {
        'totalWaterings30Days': totalWaterings,
        'plantsWatered30Days': plantsWatered,
        'averagePerDay': averagePerDay.toStringAsFixed(1),
        'mostWateredPlant': mostWateredPlant,
        'weatherBasedPercentage': weatherBasedPercentage,
        'streak': await _calculateWateringStreak(userId),
      };
    } catch (e) {
      print('Error getting watering analytics: $e');
      return {};
    }
  }

  // Get plants that need watering today
  Future<List<WateringSchedule>> getPlantsNeedingWateringToday(String userId) async {
    try {
      final schedules = await getUserSchedules(userId);
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      final needingWater = <WateringSchedule>[];

      for (final schedule in schedules) {
        if (schedule.nextWatering != null) {
          final nextWatering = schedule.nextWatering!;
          
          // Check if next watering is today
          if (nextWatering.isAfter(todayStart) && nextWatering.isBefore(todayEnd)) {
            // If weather-aware, check if we should skip due to rain
            if (schedule.weatherAware) {
              final shouldWater = await _shouldWaterBasedOnWeather();
              if (shouldWater) {
                needingWater.add(schedule);
              }
            } else {
              needingWater.add(schedule);
            }
          }
        }
      }

      return needingWater;
    } catch (e) {
      print('Error getting plants needing watering: $e');
      return [];
    }
  }

  // Calculate next watering date
  DateTime _calculateNextWatering(WateringSchedule schedule) {
    final lastWatered = schedule.lastWatered ?? DateTime.now();
    final nextDate = lastWatered.add(Duration(days: schedule.frequencyDays));
    
    // Set the preferred time
    return DateTime(
      nextDate.year,
      nextDate.month,
      nextDate.day,
      schedule.preferredTime.hour,
      schedule.preferredTime.minute,
    );
  }

  // Check if should water based on weather
  Future<bool> _shouldWaterBasedOnWeather() async {
    try {
      final weatherResult = await WeatherService.getCurrentWeather();
      if (weatherResult['success'] != true) return true;

      final weather = weatherResult['data'];
      final main = weather['main'] as Map<String, dynamic>;
      final weatherMain = weather['weather'][0]['main'] as String;
      final humidity = main['humidity'] as double? ?? 0.0;

      // Skip watering if it's raining or very humid
      if (weatherMain.toLowerCase().contains('rain')) return false;
      if (humidity > 80) return false;

      return true;
    } catch (e) {
      print('Error checking weather for watering: $e');
      return true; // Default to watering if weather check fails
    }
  }

  // Schedule watering notification
  Future<void> _scheduleWateringNotification(String userId, WateringSchedule schedule) async {
    if (schedule.nextWatering == null) return;

    try {
      final notificationId = schedule.plantId.hashCode;
      final scheduledTime = schedule.nextWatering!;

      // Cancel existing notification for this plant
      await _cancelWateringNotification(schedule.plantId);

      // Schedule new notification
      await _notificationService.scheduleNotification(
        id: notificationId,
        title: '💧 Time to Water ${schedule.plantName}!',
        body: 'Your ${schedule.plantName} is ready for its next watering.',
        scheduledTime: scheduledTime,
        payload: {
          'type': 'watering_reminder',
          'plantId': schedule.plantId,
          'plantName': schedule.plantName,
        },
      );
    } catch (e) {
      print('Error scheduling watering notification: $e');
    }
  }

  // Cancel watering notification
  Future<void> _cancelWateringNotification(String plantId) async {
    try {
      final notificationId = plantId.hashCode;
      await _notificationService.cancelNotification(notificationId);
    } catch (e) {
      print('Error canceling watering notification: $e');
    }
  }

  // Calculate watering streak
  Future<int> _calculateWateringStreak(String userId) async {
    try {
      final history = await getWateringHistory(userId, limit: 100);
      if (history.isEmpty) return 0;

      int streak = 0;
      DateTime? checkDate;

      for (final entry in history) {
        final entryDate = DateTime(entry.wateredAt.year, entry.wateredAt.month, entry.wateredAt.day);
        
        if (checkDate == null) {
          checkDate = entryDate;
          streak = 1;
        } else {
          final difference = checkDate.difference(entryDate).inDays;
          if (difference == 1) {
            streak++;
            checkDate = entryDate;
          } else if (difference > 1) {
            break;
          }
        }
      }

      return streak;
    } catch (e) {
      print('Error calculating watering streak: $e');
      return 0;
    }
  }

  // Initialize daily check for weather-based adjustments
  Future<void> initializeDailyWeatherCheck() async {
    // This would be called from main.dart to set up daily weather checks
    // Implementation would depend on background execution capabilities
  }
}
