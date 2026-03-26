import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/weather_service.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> with TickerProviderStateMixin {
  Map<String, dynamic>? _weatherData;
  Map<String, dynamic>? _forecastData;
  bool _isLoading = true;
  String? _error;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final weatherResult = await WeatherService.getCurrentWeather();
      
      if (weatherResult['success'] == true) {
        final location = weatherResult['location'];
        final forecastResult = await WeatherService.getWeatherForecast(
          location['lat'],
          location['lon'],
        );
        
        setState(() {
          _weatherData = weatherResult['data'];
          _forecastData = forecastResult['success'] == true ? forecastResult['data'] : null;
          _isLoading = false;
        });
        _fadeController.forward();
      } else {
        setState(() {
          _error = weatherResult['error'] ?? 'Failed to load weather';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
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
          'Weather & Care',
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
          : _error != null
              ? _buildErrorState()
              : _weatherData != null
                  ? _buildWeatherContent()
                  : const Center(
                      child: Text(
                        'No weather data available',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(20),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Weather Error',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error occurred',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadWeatherData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Try Again',
                style: GoogleFonts.inter(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherContent() {
    final main = _weatherData!['main'];
    final weather = _weatherData!['weather'][0];
    final temp = main['temp']?.toDouble() ?? 0.0;
    final humidity = main['humidity']?.toDouble() ?? 0.0;
    final wind = _weatherData!['wind']?['speed']?.toDouble() ?? 0.0;
    final description = weather['description'] ?? '';
    final iconCode = weather['icon'] ?? '';
    
    final recommendations = WeatherService.getCareRecommendations(_weatherData!);

    return FadeTransition(
      opacity: _fadeController,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Weather Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
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
              child: Column(
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
                              fontSize: 18,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${temp.round()}°C',
                            style: GoogleFonts.inter(
                              fontSize: 48,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            WeatherService.getWeatherDescription(description),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        WeatherService.getWeatherIcon(iconCode),
                        style: const TextStyle(fontSize: 64),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildWeatherDetail(
                        '💧',
                        'Humidity',
                        '${humidity.round()}%',
                        Colors.white,
                      ),
                      _buildWeatherDetail(
                        '💨',
                        'Wind',
                        '${wind.round()} m/s',
                        Colors.white,
                      ),
                      _buildWeatherDetail(
                        '🌡️',
                        'Feels Like',
                        '${(temp - (wind / 2)).round()}°C',
                        Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Care Recommendations
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
                        'Plant Care Recommendations',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1B5E20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...recommendations.map((recommendation) => Padding(
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
                              recommendation,
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
            const SizedBox(height: 20),

            // 3-Day Forecast
            if (_forecastData != null) _buildForecastSection(),
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
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: color.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildForecastSection() {
    final List<dynamic> forecast = _forecastData!['list']?.take(3).toList() ?? [];
    
    return Container(
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
                Icons.calendar_today,
                color: Color(0xFF1B5E20),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                '3-Day Forecast',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1B5E20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: forecast.map((item) {
              final temp = item['main']['temp']?.toDouble() ?? 0.0;
              final weather = item['weather'][0];
              final iconCode = weather['icon'] ?? '';
              final date = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
              final dayName = _getDayName(date.weekday);
              
              return Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        dayName,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1B5E20),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        WeatherService.getWeatherIcon(iconCode),
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${temp.round()}°C',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1B5E20),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return 'Today';
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }
}
