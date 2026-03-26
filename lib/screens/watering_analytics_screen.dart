import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/watering_schedule_service.dart';
import '../services/watering_schedule_service.dart';

class WateringAnalyticsScreen extends StatefulWidget {
  const WateringAnalyticsScreen({super.key});

  @override
  State<WateringAnalyticsScreen> createState() => _WateringAnalyticsScreenState();
}

class _WateringAnalyticsScreenState extends State<WateringAnalyticsScreen> with TickerProviderStateMixin {
  final WateringScheduleService _scheduleService = WateringScheduleService();
  
  bool _isLoading = true;
  Map<String, dynamic> _analytics = {};
  List<WateringHistory> _history = [];
  List<WateringSchedule> _schedules = [];

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
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final [analytics, history, schedules] = await Future.wait([
        _scheduleService.getWateringAnalytics(userId),
        _scheduleService.getWateringHistory(userId, limit: 100),
        _scheduleService.getUserSchedules(userId),
      ]);

      setState(() {
        _analytics = analytics as Map<String, dynamic>;
        _history = history as List<WateringHistory>;
        _schedules = schedules as List<WateringSchedule>;
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
          'Watering Analytics',
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
          IconButton(
            onPressed: _loadData,
            icon: const Icon(
              Icons.refresh,
              color: Color(0xFF1B5E20),
            ),
            tooltip: 'Refresh',
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
                    // Overview Cards
                    _buildOverviewCards(),
                    const SizedBox(height: 24),

                    // Weekly Chart
                    _buildWeeklyChart(),
                    const SizedBox(height: 24),

                    // Active Schedules
                    _buildActiveSchedules(),
                    const SizedBox(height: 24),

                    // Recent History
                    _buildRecentHistory(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewCards() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -0.1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOut,
      )),
      child: Column(
        children: [
          Text(
            'Last 30 Days',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard('💧', 'Total Waterings', _analytics['totalWaterings30Days']?.toString() ?? '0')),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('🌱', 'Plants Watered', _analytics['plantsWatered30Days']?.toString() ?? '0')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard('📊', 'Daily Average', _analytics['averagePerDay']?.toString() ?? '0.0')),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('🔥', 'Current Streak', '${_analytics['streak'] ?? 0} days')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String emoji, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    // Group history by day for the last 7 days
    final now = DateTime.now();
    final lastWeek = List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      
      final dayWaterings = _history.where((h) => 
        h.wateredAt.isAfter(dayStart) && h.wateredAt.isBefore(dayEnd)
      ).length;
      
      return {
        'day': DateFormat('E').format(date),
        'count': dayWaterings,
        'date': dayStart,
      };
    });

    final maxCount = lastWeek.map((d) => d['count'] as int).reduce((a, b) => a > b ? a : b).toDouble();

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOut,
      )),
      child: Container(
        padding: const EdgeInsets.all(20),
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
              'Weekly Activity',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxCount > 0 ? maxCount + 1 : 5,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => const Color(0xFF1B5E20),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final day = lastWeek[group.x.toInt()];
                        return BarTooltipItem(
                          '${day['day']}\n${day['count']} waterings',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final day = lastWeek[value.toInt()];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              day['day'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: lastWeek.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: (data['count'] as int).toDouble(),
                          color: const Color(0xFF1B5E20),
                          width: 16,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSchedules() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.15),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOut,
      )),
      child: Container(
        padding: const EdgeInsets.all(20),
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
            Row(
              children: [
                const Icon(
                  Icons.schedule,
                  color: Color(0xFF1B5E20),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Active Schedules',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
                const Spacer(),
                Text(
                  '${_schedules.length} plants',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_schedules.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF1B5E20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No active watering schedules. Tap on any plant in the dashboard to create one.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF1B5E20),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._schedules.take(5).map((schedule) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B5E20).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.local_florist,
                          color: Color(0xFF1B5E20),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              schedule.plantName,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Every ${schedule.frequencyDays} days at ${schedule.preferredTime.format(context)}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (schedule.weatherAware)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '🌤️',
                            style: GoogleFonts.inter(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              )),
            if (_schedules.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '...and ${_schedules.length - 5} more',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentHistory() {
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
            Row(
              children: [
                const Icon(
                  Icons.history,
                  color: Color(0xFF1B5E20),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Recent Activity',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_history.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.opacity_outlined,
                      color: Color(0xFF1B5E20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No watering history yet. Start watering your plants to see activity here!',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF1B5E20),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._history.take(10).map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: entry.wasScheduled 
                        ? const Color(0xFF1B5E20).withOpacity(0.1)
                        : Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: entry.wasScheduled
                          ? const Color(0xFF1B5E20).withOpacity(0.3)
                          : Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: entry.wasScheduled
                              ? const Color(0xFF1B5E20).withOpacity(0.2)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          entry.wasScheduled ? Icons.schedule : Icons.water_drop,
                          color: entry.wasScheduled
                              ? const Color(0xFF1B5E20)
                              : Colors.grey[600],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.plantName,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            if (entry.notes != null && entry.notes!.isNotEmpty)
                              Text(
                                entry.notes!,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            DateFormat('MMM d, h:mm a').format(entry.wateredAt),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          if (entry.wasScheduled)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B5E20).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Scheduled',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: const Color(0xFF1B5E20),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }
}
