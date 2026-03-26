import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherService {
  // Using OpenWeatherMap free tier - you'll need to get your own API key
  // For demo purposes, we'll use mock data
  static const String _apiKey = '386b85981c34dcf65119b7d97e09365b';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  static Future<Map<String, dynamic>> getCurrentWeather() async {
    try {
      // For demo, return mock weather data
      // In production, you'd get real location and API key
      final mockWeatherData = {
        'coord': {'lon': 77.2090, 'lat': 28.6139}, // Delhi
        'weather': [
          {
            'id': 800,
            'main': 'Clear',
            'description': 'clear sky',
            'icon': '01d'
          }
        ],
        'base': 'stations',
        'main': {
          'temp': 28.5,
          'feels_like': 27.2,
          'temp_min': 25.0,
          'temp_max': 30.0,
          'pressure': 1012,
          'humidity': 65,
          'sea_level': 1012,
          'grnd_level': 1011
        },
        'visibility': 10000,
        'wind': {'speed': 3.5, 'deg': 230},
        'clouds': {'all': 0},
        'dt': 1687905600,
        'sys': {
          'type': 1,
          'id': 9167,
          'country': 'IN',
          'sunrise': 1687851600,
          'sunset': 1687896800
        },
        'timezone': 19800,
        'id': 1261481,
        'name': 'New Delhi',
        'cod': 200
      };

      return {
        'success': true,
        'data': mockWeatherData,
        'location': {
          'lat': 28.6139,
          'lon': 77.2090,
        }
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> getWeatherForecast(double lat, double lon) async {
    try {
      // Mock 3-day forecast
      final mockForecast = {
        'cod': '200',
        'message': 0,
        'cnt': 3,
        'list': [
          {
            'dt': 1687992000,
            'main': {
              'temp': 29.0,
              'feels_like': 28.5,
              'temp_min': 26.0,
              'temp_max': 31.0,
              'pressure': 1013,
              'sea_level': 1013,
              'grnd_level': 1012,
              'humidity': 60,
              'temp_kf': 302.15
            },
            'weather': [
              {
                'id': 801,
                'main': 'Clouds',
                'description': 'few clouds',
                'icon': '02d'
              }
            ],
            'clouds': {'all': 20},
            'wind': {'speed': 4.2, 'deg': 240},
            'visibility': 10000,
            'pop': 0.1,
            'sys': {'pod': 'd'},
            'dt_txt': '2023-06-28 12:00:00'
          },
          {
            'dt': 1688078400,
            'main': {
              'temp': 27.5,
              'feels_like': 27.0,
              'temp_min': 24.0,
              'temp_max': 29.0,
              'pressure': 1014,
              'sea_level': 1014,
              'grnd_level': 1013,
              'humidity': 70,
              'temp_kf': 300.65
            },
            'weather': [
              {
                'id': 500,
                'main': 'Rain',
                'description': 'light rain',
                'icon': '10d'
              }
            ],
            'clouds': {'all': 90},
            'wind': {'speed': 3.8, 'deg': 220},
            'visibility': 10000,
            'pop': 0.8,
            'sys': {'pod': 'd'},
            'dt_txt': '2023-06-29 12:00:00'
          },
          {
            'dt': 1688164800,
            'main': {
              'temp': 26.0,
              'feels_like': 25.5,
              'temp_min': 23.0,
              'temp_max': 28.0,
              'pressure': 1015,
              'sea_level': 1015,
              'grnd_level': 1014,
              'humidity': 75,
              'temp_kf': 299.15
            },
            'weather': [
              {
                'id': 802,
                'main': 'Clouds',
                'description': 'scattered clouds',
                'icon': '03d'
              }
            ],
            'clouds': {'all': 40},
            'wind': {'speed': 3.2, 'deg': 200},
            'visibility': 10000,
            'pop': 0.3,
            'sys': {'pod': 'd'},
            'dt_txt': '2023-06-30 12:00:00'
          }
        ],
        'city': {
          'id': 1261481,
          'name': 'New Delhi',
          'coord': {'lat': 28.6139, 'lon': 77.2090},
          'country': 'IN',
          'population': 32203167,
          'timezone': 19800,
          'sunrise': 1687851600,
          'sunset': 1687896800
        }
      };

      return {
        'success': true,
        'data': mockForecast,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static String getWeatherIcon(String iconCode) {
    switch (iconCode) {
      case '01d': return '☀️';
      case '01n': return '🌙';
      case '02d': return '⛅';
      case '02n': return '☁️';
      case '03d': case '03n': return '☁️';
      case '04d': case '04n': return '☁️';
      case '09d': case '09n': return '🌧️';
      case '10d': return '🌦️';
      case '10n': return '🌧️';
      case '11d': case '11n': return '⛈️';
      case '13d': case '13n': return '❄️';
      case '50d': case '50n': return '🌫️';
      default: return '🌤️';
    }
  }

  static String getWeatherDescription(String description) {
    switch (description.toLowerCase()) {
      case 'clear sky': return 'Clear Sky';
      case 'few clouds': return 'Partly Cloudy';
      case 'scattered clouds': return 'Cloudy';
      case 'broken clouds': return 'Overcast';
      case 'shower rain': return 'Light Rain';
      case 'rain': return 'Rain';
      case 'thunderstorm': return 'Thunderstorm';
      case 'snow': return 'Snow';
      case 'mist': return 'Misty';
      case 'fog': return 'Foggy';
      default: return description;
    }
  }

  static List<String> getCareRecommendations(Map<String, dynamic> weather) {
    final List<String> recommendations = [];
    
    try {
      final main = weather['main'];
      final temp = main['temp']?.toDouble() ?? 20.0;
      final humidity = main['humidity']?.toDouble() ?? 50.0;
      final wind = weather['wind']?['speed']?.toDouble() ?? 5.0;
      final weatherMain = weather['weather'][0]['main']?.toLowerCase() ?? '';
      
      // Temperature-based recommendations
      if (temp > 30) {
        recommendations.add('🌡️ High temperature! Water plants more frequently');
        recommendations.add('🌿 Move sensitive plants to shade');
      } else if (temp < 10) {
        recommendations.add('❄️ Cold weather! Protect tropical plants');
        recommendations.add('💧 Reduce watering frequency');
      } else if (temp >= 20 && temp <= 25) {
        recommendations.add('🌱 Perfect temperature for most plants');
        recommendations.add('💧 Regular watering schedule');
      }
      
      // Humidity-based recommendations
      if (humidity > 70) {
        recommendations.add('💨 High humidity - good for tropical plants');
        recommendations.add('🍃 Ensure good air circulation');
      } else if (humidity < 30) {
        recommendations.add('🏜️ Low humidity - mist plants regularly');
        recommendations.add('💧 Group plants to increase humidity');
      }
      
      // Weather condition recommendations
      if (weatherMain.contains('rain')) {
        recommendations.add('🌧️ Rainy day - skip outdoor watering');
        recommendations.add('🏠 Move potted plants under shelter');
      } else if (weatherMain.contains('clear') && temp > 25) {
        recommendations.add('☀️ Sunny day - check soil moisture');
        recommendations.add('🌿 Provide shade for sensitive plants');
      } else if (weatherMain.contains('cloud')) {
        recommendations.add('☁️ Cloudy day - good for repotting');
        recommendations.add('🌱 Reduced light needs less water');
      }
      
      // Wind recommendations
      if (wind > 15) {
        recommendations.add('💨 Strong winds - secure tall plants');
        recommendations.add('🏠 Move delicate plants indoors');
      }
      
      // Seasonal recommendations
      final month = DateTime.now().month;
      if (month >= 3 && month <= 5) {
        recommendations.add('🌸 Spring - perfect time for repotting');
        recommendations.add('🌱 Start fertilizing schedule');
      } else if (month >= 6 && month <= 8) {
        recommendations.add('☀️ Summer - increase watering frequency');
        recommendations.add('🌿 Watch for heat stress');
      } else if (month >= 9 && month <= 11) {
        recommendations.add('🍂 Fall - reduce fertilizing');
        recommendations.add('🌿 Prepare plants for winter');
      } else {
        recommendations.add('❄️ Winter - minimal watering');
        recommendations.add('🏠 Keep tropical plants indoors');
      }
      
    } catch (e) {
      recommendations.add('⚠️ Weather data unavailable');
      recommendations.add('🌱 Follow standard care routine');
    }
    
    return recommendations;
  }
}
