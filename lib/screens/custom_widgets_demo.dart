import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/plant_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/like_button.dart';

class CustomWidgetsDemo extends StatefulWidget {
  const CustomWidgetsDemo({super.key});

  @override
  State<CustomWidgetsDemo> createState() => _CustomWidgetsDemoState();
}

class _CustomWidgetsDemoState extends State<CustomWidgetsDemo> {
  bool _isLiked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Widgets Demo'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF6F8F7),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom Buttons Section
            _buildSectionTitle('Custom Buttons'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    label: 'Primary Button',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Primary button pressed!')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    label: 'Secondary',
                    onPressed: () {},
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomButton(
              label: 'Loading Button',
              onPressed: () {},
              isLoading: true,
              width: double.infinity,
            ),

            const SizedBox(height: 32),

            // Stat Cards Section
            _buildSectionTitle('Stat Cards'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Total Plants',
                    value: '24',
                    icon: Icons.eco,
                    color: const Color(0xFF1B5E20),
                    subtitle: 'Last 30 days',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Plants stats tapped!')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    title: 'Watered Today',
                    value: '8',
                    icon: Icons.water_drop,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StatCard(
              title: 'Healthy Plants',
              value: '22',
              icon: Icons.favorite,
              color: Colors.green,
              subtitle: '92% health rate',
            ),

            const SizedBox(height: 32),

            // Like Button Section
            _buildSectionTitle('Interactive Like Button'),
            const SizedBox(height: 16),
            Row(
              children: [
                LikeButton(
                  isLiked: _isLiked,
                  onChanged: (liked) {
                    setState(() {
                      _isLiked = liked;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(liked ? 'Liked!' : 'Unliked!')),
                    );
                  },
                  size: 32,
                ),
                const SizedBox(width: 16),
                Text(
                  _isLiked ? 'You liked this!' : 'Like this plant',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Plant Cards Section
            _buildSectionTitle('Plant Cards'),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  PlantCard(
                    name: 'Monstera',
                    type: 'Monstera Deliciosa',
                    imageUrl: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b',
                    waterSchedule: '3 days',
                    healthStatus: 'Healthy',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Monstera tapped!')),
                      );
                    },
                  ),
                  PlantCard(
                    name: 'Snake Plant',
                    type: 'Sansevieria',
                    imageUrl: 'https://images.unsplash.com/photo-1485955900006-10f4d324d411',
                    waterSchedule: '5 days',
                    healthStatus: 'Needs Water',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Snake Plant tapped!')),
                      );
                    },
                  ),
                  PlantCard(
                    name: 'Pothos',
                    type: 'Epipremnum Aureum',
                    imageUrl: 'https://images.unsplash.com/photo-1520412099636-9e9e3a7c5877',
                    waterSchedule: '2 days',
                    healthStatus: 'Warning',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pothos tapped!')),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Code Examples Section
            _buildSectionTitle('Usage Examples'),
            const SizedBox(height: 16),
            _buildCodeExample(
              'Custom Button',
              '''CustomButton(
  label: 'Click Me',
  onPressed: () => print('Pressed!'),
  isLoading: false,
  color: Colors.green,
)''',
            ),
            const SizedBox(height: 16),
            _buildCodeExample(
              'Stat Card',
              '''StatCard(
  title: 'Total Plants',
  value: '24',
  icon: Icons.eco,
  color: Colors.green,
  onTap: () => print('Tapped!'),
)''',
            ),
            const SizedBox(height: 16),
            _buildCodeExample(
              'Like Button',
              '''LikeButton(
  isLiked: _isLiked,
  onChanged: (liked) => setState(() => _isLiked = liked),
)''',
            ),
            const SizedBox(height: 16),
            _buildCodeExample(
              'Plant Card',
              '''PlantCard(
  name: 'Monstera',
  type: 'Monstera Deliciosa',
  imageUrl: 'https://example.com/image.jpg',
  onTap: () => print('Plant tapped!'),
)''',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1B5E20),
      ),
    );
  }

  Widget _buildCodeExample(String title, String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              code,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
