import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/weather_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  Map<String, dynamic>? _weatherData;
  bool _isLoadingWeather = true;

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    try {
      final weatherResult = await WeatherService.getCurrentWeather();
      if (weatherResult['success'] == true) {
        setState(() {
          _weatherData = weatherResult['data'];
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingWeather = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8F7),
        elevation: 0,
        title: Text(
          'Notifications & Weather',
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
            onPressed: _loadWeatherData,
            icon: const Icon(
              Icons.refresh,
              color: Color(0xFF1B5E20),
            ),
            tooltip: 'Refresh Weather',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Weather Card
            if (_weatherData != null || _isLoadingWeather)
              Container(
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
                child: _isLoadingWeather
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      )
                    : Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current Weather',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${(_weatherData!['main']['temp']?.toDouble() ?? 0.0).round()}°C',
                                    style: GoogleFonts.inter(
                                      fontSize: 32,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    _weatherData!['weather'][0]['description'] ?? '',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                WeatherService.getWeatherIcon(_weatherData!['weather'][0]['icon'] ?? ''),
                                style: const TextStyle(fontSize: 48),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildWeatherDetail(
                                '💧',
                                'Humidity',
                                '${(_weatherData!['main']['humidity']?.toDouble() ?? 0.0).round()}%',
                                Colors.white,
                              ),
                              _buildWeatherDetail(
                                '💨',
                                'Wind',
                                '${(_weatherData!['wind']?['speed']?.toDouble() ?? 0.0).round()} m/s',
                                Colors.white,
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            const SizedBox(height: 20),

            // Today's Notifications
            Container(
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
                    'Today',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildNotificationItem(
                    '🌱 Plant Care Reminder',
                    'Your Monstera needs watering today!',
                    '2 hours ago',
                    Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  _buildNotificationItem(
                    '💧 Water Complete',
                    'Snake Plant has been watered',
                    '5 hours ago',
                    Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildNotificationItem(
                    '🌿 New Milestone',
                    'Your Pothos has been growing for 30 days!',
                    '1 day ago',
                    const Color(0xFF1B5E20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Weather-based Care Tips
            if (_weatherData != null)
              Container(
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
                          Icons.lightbulb_outline,
                          color: Color(0xFF1B5E20),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Weather-based Care Tips',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1B5E20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...WeatherService.getCareRecommendations(_weatherData!).map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B5E20).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF1B5E20).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                tip,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFF1B5E20),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(String emoji, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: color.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationItem(
    String title,
    String message,
    String time,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                title.split(' ')[0],
                style: GoogleFonts.inter(
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
