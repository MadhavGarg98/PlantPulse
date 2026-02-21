import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'premium_dashboard_screen.dart';

class StatelessStatefulDemo extends StatefulWidget {
  const StatelessStatefulDemo({super.key});

  @override
  State<StatelessStatefulDemo> createState() => _StatelessStatefulDemoState();
}

class _StatelessStatefulDemoState extends State<StatelessStatefulDemo> 
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1B5E20)),
        ),
        title: Text(
          'Widget Demo',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1B5E20),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stateless Widget Demo Section
              _buildSectionTitle('Stateless Widget Demo'),
              const SizedBox(height: 16),
              const StaticHeaderWidget(),
              const SizedBox(height: 32),
              
              // Stateful Widget Demo Section
              _buildSectionTitle('Stateful Widget Demo'),
              const SizedBox(height: 16),
              const InteractiveCounterWidget(),
              const SizedBox(height: 32),
              
              // Theme Toggle Demo
              _buildSectionTitle('Theme Toggle Demo'),
              const SizedBox(height: 16),
              const ThemeToggleWidget(),
              const SizedBox(height: 32),
              
              // Color Changer Demo
              _buildSectionTitle('Color Changer Demo'),
              const SizedBox(height: 16),
              const ColorChangerWidget(),
              const SizedBox(height: 32),
              
              // Plant Growth Simulator (PlantPulse themed)
              _buildSectionTitle('Plant Growth Simulator'),
              const SizedBox(height: 16),
              const PlantGrowthWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF111111),
      ),
    );
  }
}

// STATELESS WIDGET EXAMPLE
// This widget displays static content and never changes once built
class StaticHeaderWidget extends StatelessWidget {
  const StaticHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1B5E20).withOpacity(0.8),
            const Color(0xFF4CAF50).withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stateless Widget',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Static content - never changes after build',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'This is a StatelessWidget. It displays static content that remains constant unless rebuilt by its parent. Perfect for headers, labels, and static UI elements.',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}

// STATEFUL WIDGET EXAMPLE 1: Interactive Counter
class InteractiveCounterWidget extends StatefulWidget {
  const InteractiveCounterWidget({super.key});

  @override
  State<InteractiveCounterWidget> createState() => _InteractiveCounterWidgetState();
}

class _InteractiveCounterWidgetState extends State<InteractiveCounterWidget> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _decrementCounter() {
    setState(() {
      if (_counter > 0) _counter--;
    });
  }

  void _resetCounter() {
    setState(() {
      _counter = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calculate,
                  color: Color(0xFF1B5E20),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Interactive Counter',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'StatefulWidget with dynamic updates',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Counter Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8F7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                Text(
                  'Current Count',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_counter',
                  style: GoogleFonts.inter(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Control Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _decrementCounter,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5E7EB),
                    foregroundColor: const Color(0xFF111111),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Decrease',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _incrementCounter,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Increase',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _resetCounter,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                child: Text(
                  'Reset',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// STATEFUL WIDGET EXAMPLE 2: Theme Toggle
class ThemeToggleWidget extends StatefulWidget {
  const ThemeToggleWidget({super.key});

  @override
  State<ThemeToggleWidget> createState() => _ThemeToggleWidgetState();
}

class _ThemeToggleWidgetState extends State<ThemeToggleWidget> {
  bool _isDarkMode = false;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isDarkMode 
                      ? const Color(0xFF1B5E20).withOpacity(0.1)
                      : const Color(0xFFFFB74D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: _isDarkMode ? const Color(0xFF1B5E20) : const Color(0xFFFFB74D),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme Toggle',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Current: ${_isDarkMode ? 'Dark Mode' : 'Light Mode'}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Theme Preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF6F8F7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isDarkMode ? const Color(0xFF333333) : const Color(0xFFE5E7EB),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: _isDarkMode ? Colors.white : const Color(0xFF1B5E20),
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isDarkMode ? 'Dark Mode' : 'Light Mode',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: _isDarkMode ? Colors.white : const Color(0xFF1B5E20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'This preview changes based on the theme toggle above. Stateful widgets allow for dynamic UI updates based on user interactions.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: _isDarkMode ? Colors.white70 : const Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Toggle Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _toggleTheme,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isDarkMode ? const Color(0xFF1B5E20) : const Color(0xFFFFB74D),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// STATEFUL WIDGET EXAMPLE 3: Color Changer
class ColorChangerWidget extends StatefulWidget {
  const ColorChangerWidget({super.key});

  @override
  State<ColorChangerWidget> createState() => _ColorChangerWidgetState();
}

class _ColorChangerWidgetState extends State<ColorChangerWidget> {
  Color _selectedColor = const Color(0xFF1B5E20);

  final List<Color> _colors = [
    const Color(0xFF1B5E20), // Deep Green
    const Color(0xFF4CAF50), // Light Green
    const Color(0xFF2196F3), // Blue
    const Color(0xFFFFB74D), // Orange
    const Color(0xFFE53935), // Red
    const Color(0xFF9C27B0), // Purple
  ];

  void _changeColor(Color color) {
    setState(() {
      _selectedColor = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _selectedColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.palette,
                  color: _selectedColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Color Changer',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap colors to change the theme',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Color Preview
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: _selectedColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _selectedColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Selected Color',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Color Options
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _colors.map((color) {
              final isSelected = color == _selectedColor;
              return GestureDetector(
                onTap: () => _changeColor(color),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(25),
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: isSelected ? 15 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 24,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// STATEFUL WIDGET EXAMPLE 4: Plant Growth Simulator (PlantPulse Themed)
class PlantGrowthWidget extends StatefulWidget {
  const PlantGrowthWidget({super.key});

  @override
  State<PlantGrowthWidget> createState() => _PlantGrowthWidgetState();
}

class _PlantGrowthWidgetState extends State<PlantGrowthWidget> 
    with TickerProviderStateMixin {
  int _growthLevel = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _growPlant() {
    setState(() {
      if (_growthLevel < 5) {
        _growthLevel++;
      }
    });
  }

  void _resetPlant() {
    setState(() {
      _growthLevel = 0;
    });
  }

  String _getPlantEmoji() {
    switch (_growthLevel) {
      case 0:
        return '🌱';
      case 1:
        return '🌿';
      case 2:
        return '🍃';
      case 3:
        return '🌾';
      case 4:
        return '🌳';
      case 5:
        return '🌲';
      default:
        return '🌱';
    }
  }

  String _getGrowthStatus() {
    switch (_growthLevel) {
      case 0:
        return 'Seed';
      case 1:
        return 'Sprout';
      case 2:
        return 'Growing';
      case 3:
        return 'Mature';
      case 4:
        return 'Tree';
      case 5:
        return 'Fully Grown';
      default:
        return 'Seed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.eco,
                  color: Color(0xFF1B5E20),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plant Growth Simulator',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Watch your plant grow!',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Plant Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1B5E20).withOpacity(0.05),
                  const Color(0xFF4CAF50).withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Text(
                        _getPlantEmoji(),
                        style: const TextStyle(fontSize: 80),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  _getGrowthStatus(),
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Growth Level: $_growthLevel/5',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Progress Bar
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _growthLevel / 5,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B5E20),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Control Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _growthLevel < 5 ? _growPlant : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    _growthLevel < 5 ? 'Water Plant' : 'Fully Grown!',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _resetPlant,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                child: Text(
                  'Reset',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
