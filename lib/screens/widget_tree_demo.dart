import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WidgetTreeDemo extends StatefulWidget {
  const WidgetTreeDemo({super.key});

  @override
  State<WidgetTreeDemo> createState() => _WidgetTreeDemoState();
}

class _WidgetTreeDemoState extends State<WidgetTreeDemo> 
    with TickerProviderStateMixin {
  int _counter = 0;
  Color _backgroundColor = Colors.green.shade50;
  bool _showWidgetTree = false;
  bool _isDarkMode = false;
  double _containerSize = 100.0;
  String _selectedPlant = '🌱';
  final List<String> _plants = ['🌱', '🌿', '🍃', '🌾', '🌵', '🎋'];
  
  late AnimationController _pulseController;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
      if (_counter % 5 == 0) {
        _backgroundColor = Colors.primaries[_counter ~/ 5 % Colors.primaries.length].shade100;
      }
    });
  }

  void _toggleWidgetTree() {
    setState(() {
      _showWidgetTree = !_showWidgetTree;
    });
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
      _backgroundColor = _isDarkMode ? Colors.grey.shade800 : Colors.green.shade50;
    });
  }

  void _changeContainerSize() {
    setState(() {
      _containerSize = _containerSize == 100.0 ? 150.0 : 100.0;
    });
  }

  void _changePlant() {
    setState(() {
      final currentIndex = _plants.indexOf(_selectedPlant);
      _selectedPlant = _plants[(currentIndex + 1) % _plants.length];
    });
  }

  void _rotatePlant() {
    _rotationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          'Widget Tree & Reactive UI Demo',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green.shade600,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade600, Colors.green.shade800],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderSection(),
            const SizedBox(height: 20),
            _buildInteractiveCounterSection(),
            const SizedBox(height: 20),
            _buildPlantAnimationSection(),
            const SizedBox(height: 20),
            _buildThemeToggleSection(),
            const SizedBox(height: 20),
            _buildWidgetTreeSection(),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: _toggleWidgetTree,
            backgroundColor: Colors.blue.shade600,
            icon: Icon(_showWidgetTree ? Icons.visibility_off : Icons.visibility),
            label: Text(_showWidgetTree ? 'Hide Tree' : 'Show Tree'),
          ).animate().scale(delay: 200.ms),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            onPressed: _incrementCounter,
            backgroundColor: Colors.green.shade600,
            icon: const Icon(Icons.add),
            label: const Text('Increment'),
          ).animate().scale(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '🌿 PlantPulse Widget Tree Demo 🌿',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Explore Flutter\'s Reactive UI Model',
            style: GoogleFonts.roboto(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    ).animate().slideY(duration: 500.ms).fadeIn();
  }

  Widget _buildInteractiveCounterSection() {
    return Card(
      elevation: 8,
      shadowColor: Colors.green.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Reactive Counter',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            const SizedBox(height: 15),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _containerSize,
              height: _containerSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade300, Colors.green.shade500],
                ),
                borderRadius: BorderRadius.circular(_containerSize / 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$_counter',
                  style: GoogleFonts.poppins(
                    fontSize: _containerSize / 3,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ).animate(target: _counter > 0 ? 1 : 0).scale(),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _incrementCounter,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _changeContainerSize,
                  icon: const Icon(Icons.aspect_ratio),
                  label: const Text('Resize'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().slideX(duration: 600.ms);
  }

  Widget _buildPlantAnimationSection() {
    return Card(
      elevation: 8,
      shadowColor: Colors.green.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Interactive Plant Animation',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            const SizedBox(height: 20),
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_pulseController.value * 0.2),
                  child: AnimatedBuilder(
                    animation: _rotationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationController.value * 2 * 3.14159,
                        child: Text(
                          _selectedPlant,
                          style: const TextStyle(fontSize: 80),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _changePlant,
                  icon: const Icon(Icons.eco),
                  label: const Text('Change Plant'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _rotatePlant,
                  icon: const Icon(Icons.rotate_right),
                  label: const Text('Rotate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().slideY(duration: 700.ms);
  }

  Widget _buildThemeToggleSection() {
    return Card(
      elevation: 8,
      shadowColor: Colors.green.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Theme & Background',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            const SizedBox(height: 15),
            SwitchListTile(
              title: Text(
                _isDarkMode ? 'Dark Mode' : 'Light Mode',
                style: GoogleFonts.roboto(fontSize: 16),
              ),
              subtitle: Text(
                'Toggle to change background color',
                style: GoogleFonts.roboto(fontSize: 12),
              ),
              value: _isDarkMode,
              onChanged: (value) => _toggleTheme(),
              activeTrackColor: Colors.green.shade600,
              activeColor: Colors.green.shade800,
            ),
          ],
        ),
      ),
    ).animate().slideX(duration: 800.ms);
  }

  Widget _buildWidgetTreeSection() {
    if (!_showWidgetTree) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 8,
      shadowColor: Colors.blue.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Widget Tree Hierarchy',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTreeItem('Scaffold', isRoot: true),
                  _buildTreeItem('├── AppBar'),
                  _buildTreeItem('│   ├── Container (Gradient)'),
                  _buildTreeItem('│   └── Text (Title)'),
                  _buildTreeItem('├── SingleChildScrollView'),
                  _buildTreeItem('│   └── Column'),
                  _buildTreeItem('│       ├── Container (Header)'),
                  _buildTreeItem('│       ├── Card (Counter)'),
                  _buildTreeItem('│       │   └── AnimatedContainer'),
                  _buildTreeItem('│       ├── Card (Plant Animation)'),
                  _buildTreeItem('│       │   └── Transform.scale'),
                  _buildTreeItem('│       └── Card (Theme Toggle)'),
                  _buildTreeItem('└── FloatingActionButtonColumn'),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Text(
              'Reactive Elements:',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 10),
            ...['Counter Value', 'Background Color', 'Plant Emoji', 'Container Size', 'Theme Mode'].map(
              (item) => Padding(
                padding: const EdgeInsets.only(left: 10, top: 5),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: Colors.green.shade600),
                    const SizedBox(width: 10),
                    Text(
                      item,
                      style: GoogleFonts.roboto(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildTreeItem(String text, {bool isRoot = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 2),
      child: Text(
        text,
        style: GoogleFonts.robotoMono(
          fontSize: 12,
          fontWeight: isRoot ? FontWeight.bold : FontWeight.normal,
          color: isRoot ? Colors.blue.shade800 : Colors.black87,
        ),
      ),
    );
  }
}
