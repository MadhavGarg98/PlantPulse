import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/plant_model.dart';
import '../services/watering_schedule_service.dart';
import '../services/firestore_service.dart';
import '../widgets/custom_button.dart';

class PlantScheduleScreen extends StatefulWidget {
  final PlantModel plant;

  const PlantScheduleScreen({
    super.key,
    required this.plant,
  });

  @override
  State<PlantScheduleScreen> createState() => _PlantScheduleScreenState();
}

class _PlantScheduleScreenState extends State<PlantScheduleScreen> with TickerProviderStateMixin {
  final WateringScheduleService _scheduleService = WateringScheduleService();
  final FirestoreService _firestoreService = FirestoreService();
  
  bool _isLoading = true;
  bool _hasSchedule = false;
  bool _isSaving = false;
  
  // Form controllers
  int _selectedFrequency = 3; // Default: every 3 days
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool _weatherAware = true;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadExistingSchedule();
  }

  Future<void> _loadExistingSchedule() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final schedules = await _scheduleService.getUserSchedules(userId);
      final existingSchedule = schedules.firstWhere(
        (s) => s.plantId == widget.plant.id,
        orElse: () => WateringSchedule(
          plantId: widget.plant.id!,
          plantName: widget.plant.name,
          frequencyDays: 3,
          preferredTime: const TimeOfDay(hour: 9, minute: 0),
          createdAt: DateTime.now(),
        ),
      );

      setState(() {
        _hasSchedule = schedules.any((s) => s.plantId == widget.plant.id);
        _selectedFrequency = existingSchedule.frequencyDays;
        _selectedTime = existingSchedule.preferredTime;
        _weatherAware = existingSchedule.weatherAware;
        _isLoading = false;
      });

      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8F7),
        elevation: 0,
        title: Text(
          'Watering Schedule',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1B5E20),
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF1B5E20),
          ),
        ),
        actions: [
          if (_hasSchedule)
            IconButton(
              onPressed: _deleteSchedule,
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),
              tooltip: 'Delete Schedule',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1B5E20),
              ),
            )
          : FadeTransition(
              opacity: _fadeController,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Plant Info Card
                    _buildPlantInfoCard(),
                    const SizedBox(height: 24),

                    // Schedule Form
                    _buildScheduleForm(),
                    const SizedBox(height: 24),

                    // Save Button
                    _buildSaveButton(),
                    const SizedBox(height: 24),

                    // Quick Tips
                    _buildQuickTips(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPlantInfoCard() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -0.1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOut,
      )),
      child: Container(
        padding: const EdgeInsets.all(20),
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
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B5E20).withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.local_florist,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.plant.name,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.plant.type,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _hasSchedule 
                    ? Colors.green.withOpacity(0.3)
                    : Colors.orange.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _hasSchedule ? 'Scheduled' : 'No Schedule',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleForm() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOut,
      )),
      child: Container(
        padding: const EdgeInsets.all(24),
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
            Text(
              'Schedule Settings',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 20),

            // Frequency Selection
            Text(
              'Watering Frequency',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _buildFrequencySelector(),
            const SizedBox(height: 24),

            // Time Selection
            Text(
              'Preferred Time',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _buildTimeSelector(),
            const SizedBox(height: 24),

            // Weather Aware Toggle
            _buildWeatherAwareToggle(),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencySelector() {
    final frequencies = [
      {'days': 1, 'label': 'Daily', 'icon': '🌱'},
      {'days': 2, 'label': 'Every 2 days', 'icon': '🌿'},
      {'days': 3, 'label': 'Every 3 days', 'icon': '🍃'},
      {'days': 7, 'label': 'Weekly', 'icon': '🌾'},
      {'days': 14, 'label': 'Bi-weekly', 'icon': '🌻'},
    ];

    return Column(
      children: frequencies.map((freq) {
        final isSelected = _selectedFrequency == freq['days'];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => setState(() => _selectedFrequency = freq['days'] as int),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFF1B5E20).withOpacity(0.1)
                    : Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected 
                      ? const Color(0xFF1B5E20)
                      : Colors.grey.withOpacity(0.3),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    freq['icon'] as String,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      freq['label'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected 
                            ? const Color(0xFF1B5E20)
                            : Colors.black87,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF1B5E20),
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeSelector() {
    return GestureDetector(
      onTap: _selectTime,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.schedule,
              color: Color(0xFF1B5E20),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedTime.format(context),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherAwareToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_queue,
            color: Color(0xFF1B5E20),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weather-Aware Scheduling',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Skip watering on rainy days',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _weatherAware,
            onChanged: (value) => setState(() => _weatherAware = value),
            activeColor: const Color(0xFF1B5E20),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return CustomButton(
      text: _hasSchedule ? 'Update Schedule' : 'Create Schedule',
      isLoading: _isSaving,
      onPressed: _saveSchedule,
    );
  }

  Widget _buildQuickTips() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOut,
      )),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1B5E20).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF1B5E20).withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: Color(0xFF1B5E20),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Quick Tips',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._getPlantSpecificTips().map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '•',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF1B5E20),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF1B5E20),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  List<String> _getPlantSpecificTips() {
    final plantType = widget.plant.type.toLowerCase();
    
    if (plantType.contains('succulent') || plantType.contains('cactus')) {
      return [
        'Succulents prefer less frequent watering',
        'Allow soil to dry completely between waterings',
        'Water every 2-3 weeks in winter',
      ];
    } else if (plantType.contains('fern') || plantType.contains('tropical')) {
      return [
        'Tropical plants love consistent moisture',
        'Keep soil evenly moist but not waterlogged',
        'Mist leaves regularly for humidity',
      ];
    } else if (plantType.contains('snake') || plantType.contains('pothos')) {
      return [
        'These plants are drought-tolerant',
        'Water when top inch of soil is dry',
        'Better to underwater than overwater',
      ];
    } else {
      return [
        'Check soil moisture before watering',
        'Adjust frequency based on season',
        'Consider weather conditions',
      ];
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveSchedule() async {
    setState(() => _isSaving = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final schedule = WateringSchedule(
        plantId: widget.plant.id!,
        plantName: widget.plant.name,
        frequencyDays: _selectedFrequency,
        preferredTime: _selectedTime,
        weatherAware: _weatherAware,
        createdAt: DateTime.now(),
      );

      final success = await _scheduleService.saveWateringSchedule(userId, schedule);

      if (success) {
        // Update plant model
        final updatedPlant = widget.plant.copyWith(
          hasWateringSchedule: true,
          wateringFrequencyDays: _selectedFrequency,
          preferredWateringTime: _selectedTime.format(context),
        );

        await _firestoreService.updatePlant(userId, updatedPlant);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _hasSchedule 
                    ? 'Watering schedule updated successfully!' 
                    : 'Watering schedule created successfully!',
              ),
              backgroundColor: const Color(0xFF1B5E20),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Failed to save schedule');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteSchedule() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Schedule',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete the watering schedule for ${widget.plant.name}?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: Colors.grey,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final success = await _scheduleService.deleteWateringSchedule(userId, widget.plant.id!);

      if (success) {
        // Update plant model
        final updatedPlant = widget.plant.copyWith(
          hasWateringSchedule: false,
          wateringFrequencyDays: null,
          preferredWateringTime: null,
        );

        await _firestoreService.updatePlant(userId, updatedPlant);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Watering schedule deleted for ${widget.plant.name}'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Failed to delete schedule');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
